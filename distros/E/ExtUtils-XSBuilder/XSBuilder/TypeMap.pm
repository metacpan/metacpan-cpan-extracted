package ExtUtils::XSBuilder::TypeMap;

use strict;
use warnings FATAL => 'all';

use ExtUtils::XSBuilder::FunctionMap ();
use ExtUtils::XSBuilder::CallbackMap ();
use ExtUtils::XSBuilder::StructureMap ();
use ExtUtils::XSBuilder::MapUtil qw(list_first function_table structure_table callback_table callback_hash);
use Data::Dumper ;

our @ISA = qw(ExtUtils::XSBuilder::MapBase);

sub new {
    my $class = shift;
    my $self = bless { INCLUDE => [], wrapxs => shift }, $class;

    $self->{function_map}  = ExtUtils::XSBuilder::FunctionMap ->new ($self -> {wrapxs}),
    $self->{structure_map} = ExtUtils::XSBuilder::StructureMap->new ($self -> {wrapxs}),
    $self->{callback_map}  = ExtUtils::XSBuilder::CallbackMap ->new ($self -> {wrapxs}),

    $self->get;
    $self;
}

my %special = map { $_, 1 } qw(UNDEFINED NOTIMPL CALLBACK);

sub special {
    my($self, $class) = @_;
    return $special{$class};
}

sub function_map  { shift->{function_map}->get  }
sub structure_map { shift->{structure_map}->get }
sub callback_map  { shift->{callback_map}->get }

sub parse {
    my($self, $fh, $map) = @_;

    while ($fh->readline) {
        if (/E=/) {
            my %args = $self->parse_keywords($_);
            while (my($key,$val) = each %args) {
                push @{ $self->{$key} }, $val;
            }
            next;
        }

        my @aliases;
        my($type, $class, $typemapid, $aliastypes, $malloctype) = split /\s*\|\s*/, $_, 5;
        if (!$typemapid && $class)
            {
            if ($class =~ /::/) {
                $typemapid = 'T_PTROBJ';
                }
            else {
                $typemapid = "T_$class";
            }
        }
        $class ||= 'UNDEFINED';

        if ($type =~ s/^struct\s+(.*)/$1/) {
            push @aliases,
              "$type *",        "const $type *",
              $type,            "const $type", 
              "struct $type",   "const struct $type",
              "struct $type *", "const struct $type *",
              "$type **",       "const $type **" ;

            my $cname = $class;
            if ($cname =~ s/::/__/g) {
                push @{ $self->{typedefs} }, [$type, $cname];
            }
        }
        elsif ($type =~ /_t$/) {
            push @aliases, $type, "$type *", "const $type *";
        }
        else {
            push @aliases, $type;
        }

        my $t = { class => $class,
                  typemapid => $typemapid } ;
        $t -> {aliastypes} = [ split (/\s*,\s*/, $aliastypes) ]  if ($aliastypes) ;
        $t -> {malloctype} = $malloctype if ($malloctype) ;

        for (@aliases) {
            $map->{$_} = $t ; 
        }
    }
}

sub get {
    my $self = shift;

    $self->{map} ||= $self->parse_map_files;
}

my $ignore = join '|', qw{
ap_LINK ap_HOOK _ UINT union._
union.block_hdr cleanup process_chain
iovec struct.rlimit Sigfunc in_addr_t
};

sub should_ignore {
    my($self, $type) = @_;
    return 1 if $type =~ /^($ignore)/o;
}

sub is_callback {
    my($self, $type) = @_;
    return 1 if $type =~ /\(/ and $type =~ /\)/; #XXX: callback
}

sub exists {
    my($self, $type) = @_;

    return 1 if $self->is_callback($type) || $self->should_ignore($type);

    $type =~ s/\[\d+\]$//; #char foo[64]

    return exists $self->get->{$type};
}

sub map_type {
    my($self, $type, $quiet) = @_;
    my $t = $self->get->{$type};
    my $class = $t -> {class} ;

    unless ($class and ! $self->special($class))
        {
        print "WARNING: Type '$type' not in mapfile\n" if (!$quiet);
        return undef ;
        }
    if ($class =~ /(.*?)::$/) {
        return $1 ;
    }
    if ($class =~ /::/) {
        return $class;
    }
    else {
        return $type;
    }
}

sub map_malloc_type {
    my($self, $type) = @_;
    my $t = $self->get->{$type};
    return $t -> {malloctype} ;
}

sub map_class {
    my($self, $type) = @_;
    my $t = $self->get->{$type};
    my $class = $t -> {class} ;

    return unless $class and ! $self->special($class);
    if ($class =~ /(.*?)::$/) {
        return $1 ;
    }
    return $class ;
}

sub null_type {
    my($self, $type) = @_;
    my $t = $self->get->{$type};
    my $class = $t -> {class} ;

    if ($class =~ /^[INU]V/) {
        return '0';
    }
    elsif ($class =~ /^(U_)?CHAR$/) {
        return '0'; # xsubpp seems to mangle q{'\0'}
    }
    else {
        return 'NULL';
    }
}

sub can_map {
    my $self = shift;
    my $map = shift;
    my $return_type = shift ;

    if (!$self->map_type($return_type))
        {
        print "WARNING: Cannot map return type $return_type for function ", $map->{name} || '???', "\n" ;
        return undef ;
        }

    return 1 if ($map->{argspec}) ;

    for (@_) {
        if (!$self->map_type($_))
            {
            print "WARNING: Cannot map type $_ for function ", $map->{name} || '???', "\n" ;
            return undef ;
            }
    }

    return 1;
}

sub map_arg {
    my($self, $arg) = @_;
    #print Dumper ($arg), 'map ', $self->map_type($arg->{type}), "\n" ;
    return {
       name    => $arg->{name},
       default => $arg->{default},
       type    => $self->map_type($arg->{type}) || $arg->{type},
       rtype   => $arg->{type},
       class   => $self->{map}->{$arg->{type}}->{class} || "",
    }
}

sub map_args {
    my($self, $func, $entry) = @_;

    #my $entry = $self->function_map->{ $func->{name} };
    my $argspec = $entry->{argspec};
    my $args = [];
    my $retargs = [];

    if ($argspec) {
        $entry->{orig_args} = [ map $_->{name}, @{ $func->{args} } ];

        #print "argspec ", Dumper($argspec) ;
        for my $arg (@$argspec) {
            my $default;
            my $return  ;
            if ($arg =~ /^<(.*?)$/) {
                $arg = $1 ;
                $return = 1 ;
                }
            
            ($arg, $default) = split /=/, $arg, 2;
            my($type, $name) ;
            if ($arg =~ /^(.+)\s*:\s*(.+)$/)
                {
                $type = $1 ;
                $name = $2 ;
                }

            #my($type, $name) = split /:(?:[^:])/, $arg, 2;

            my $arghash ;
            if ($type and $name) {
                $arghash = {
                   name => $name,
                   type => $type,
                   default => $default,
                };
            }
            else {
                my $e = list_first { $_->{name} eq $arg } @{ $func->{args} };
                if ($e) {
                    $arghash = { %$e, default => $default};
                }
                elsif ($arg eq '...') {
                    $arghash = { name => '...', type => 'SV *'};
                }
                else {
                    warn "bad argspec: $func->{name} ($arg)\n", Dumper ($func->{args}) ;
                }
            }
            if ($arghash){
                if ($return) {
                    $arghash -> {return} = 1 ;
                    $arghash -> {type} =~ s/\s*\*$// ;
                    push @$retargs, $arghash  ;
                } 
                else {
                    push @$args, $arghash  ;
                }
            }
        }
    }
    else {
        $args = $func->{args};
    }

    return ([ map $self->map_arg($_), @$args ], [ map $self->map_arg($_), @$retargs ]) ;
}

# ============================================================================

sub map_cb_or_func {
    my($self, $func, $map, $class) = @_;

    return unless $map;

    return unless $self->can_map($map, $func->{return_type} || 'void',
                                 map $_->{type}, @{ $func->{args} });
    my ($mfargs, $mfretargs) = $self->map_args($func, $map) ;

    my $mf = {
       name        => $func->{name},
       comment     => $func->{comment},
       return_type => $self->map_type($map->{return_type} ||
                                      $func->{return_type} || 'void'),
       args        => $mfargs,
       retargs     => $mfretargs,
       perl_name   => $map->{name},
    };

    for (qw(dispatch argspec dispatch_argspec orig_args prefix)) {
        $mf->{$_} = $map->{$_};
    }

    $mf->{class} = $class if ($class) ;

    unless ($mf->{class}) {
        $mf->{class} = $map->{class} || $self->first_class($mf);
        #print "GUESS class=$mf->{class} for $mf->{name}\n";
    }

    $mf->{prefix} ||= $self -> {function_map} -> guess_prefix($mf);

    $mf->{module} = $map->{module} || $mf->{class};

    $mf;
}

# ============================================================================

sub map_function {
    my($self, $func) = @_;

    my $map = $self->function_map->{ $func->{name} };
    return unless $map;

    return $self -> map_cb_or_func ($func, $map) ;
}

# ============================================================================

sub map_callback {
    my($self, $callb, $class) = @_;

    my $name = $callb -> {type} ;
    my $callback = callback_hash ($self -> {wrapxs}) -> {$name} ;
    #print $callb -> {name} || '???' ,"   $name -> ", $callback || '-', "\n" ;
    return unless $callback;

    my $map = $self->callback_map->{ $name };
    #print "$name -> map=", $map || '-', "\n" ;
    return unless $map;

    my $cb = $self -> map_cb_or_func ($callback, $map, $class) ;

    return unless $cb ;

    my $orig_args = $cb -> {orig_args} ;
    $orig_args = [ map $_->{name}, @{ $cb->{args} } ] if (!$orig_args) ;
    
    my %args    = map { $_->{name} => $_ } @{ $cb->{args} } ;
    my %retargs = map { $_->{name} => $_ } @{ $cb->{retargs} } ;

    #print "mcb ", Dumper($cb), " cba ", Dumper($callback->{args}) , " args ", Dumper(\%args) ;

    $cb -> {orig_args} = [ map ($retargs{$_}?"\&$_":(($args{$_}{type} !~ /::/) || ($args{$_}{rtype} =~ /\*$/)?
                                         $_:"*$_"), @{ $orig_args }) ];

    my $cbargs      = [ { type => $class, name => '__self'} ] ;
    push @$cbargs, @{ $cb->{args} } if (@{ $cb->{args}}) ;
    $cb->{args} = $cbargs ;

    #print 'func', Dumper($callback), 'map', Dumper($map), 'cb', Dumper($cb) ;

    return $cb ;
}

# ============================================================================

sub map_structure {
    my($self, $struct) = @_;

    my($class, @elts);
    my $stype = $struct->{type};

    return unless ($class = $self->map_type($stype)) ;

    my $module = $self->{structure_map}->{MODULES}->{$stype} || $class ;
    for my $e (@{ $struct->{elts} }) {
        my($name, $type) = ($e->{name}, $e->{type});
        my $rtype;
        my $mapping ;

        if (!exists ($self->structure_map->{$stype}->{$name}))
            {
            if (!$name)
                {
                print "WARNING: The following struct element is not in mapfile and has no name\n", Dumper ($e) ;
                }
            else
                {
                print "WARNING: $name not in mapfile\n" ;
                }
            next ;
            }
        if (!($mapping = $self->structure_map->{$stype}->{$name}))
            {
            print "WARNING: $stype for $name not in mapfile\n" ;
            next ;
            }
        my $mallocmap = $self->structure_map->{$stype}{-malloc} ;
        my $freemap   = $self->structure_map->{$stype}{-free} ;

        #print 'mapping: ', Dumper($mapping, $type) ;

        if ($rtype = $self->map_type($type, 1)) {
            #print "rtype=$rtype\n" ;
            my $malloctype = $self->map_malloc_type($type) ;
            push @elts, {
               name    => $name,
               perl_name    => $mapping -> {perl_name} || $name,
               comment => $e -> {comment},
               type    => $mapping -> {type} || $rtype,
               rtype   => $type,
               default => $self->null_type($type),
               pool    => $self->class_pool($class),
               class   => $self->{map}->{$type}{class} || "",
               $malloctype?(malloc  => $mallocmap -> {$malloctype}):(), 
               $malloctype?(free    => $freemap -> {$malloctype}):(), 
            };
    
            #print Dumper($elts[-1], $stype, $mallocmap, $self->map_malloc_type($type)) ;
        }
        elsif ($rtype = $self->map_callback($e, $class)) {
            push @elts, {
               name    => $name,
               perl_name    => $mapping -> {perl_name} || $name,
               func    => { %$rtype, name => $name, perl_name => $rtype->{alias} || $name, module => $module, dispatch => "(*__self->$name)", comment => $e -> {comment}},
               rtype   => $type,
               default => 'NULL',
               #pool    => $self->class_pool($class),
               class   => $class || "",
               callback => 1,
            };
        }
        else
            {
            print "WARNING: Type '$type' for struct memeber '$name' in not in types mapfile\n" ;
            }

    }

    return {
       module       => $module,
       class        => $class,
       type         => $stype,
       elts         => \@elts,
       has_new      => $self->structure_map->{$stype}->{'new'}?1:0,
       has_private  => $self->structure_map->{$stype}->{'private'}?1:0,
       comment      => $struct -> {comment},

    };
}

sub destructor {
    my($self, $prefix) = @_;
    $self->function_map->{$prefix . 'DESTROY'};
}


sub first_class_ok { 1 } ;

sub first_class {
    my($self, $func) = @_;
    my $map = $self->get ;

    for my $e (@{ $func->{args} }) {
        ###next unless $e->{type} =~ /::/;
        # use map -> rtype to catch class::
        next unless $map->{$e->{rtype}}{class} =~ /::/;
        
        #there are alot of util functions that take an APR::Pool
        #that do not belong in the APR::Pool class
        ###next if (!$self -> first_class_ok ($func, $e)) ;
        next if $e->{type} eq 'APR::Pool' and $func->{name} !~ /^apr_pool/;
        return $1 if ($e->{type} =~ /^(.*?)::$/) ;
        return $e->{type};
    }

    return $func->{name} =~ /^apr_/ ? 'APR' : 'Apache';
}

sub check {
    my $self = shift;

    my(@types, @missing, %seen);

    for my $entry (@{ structure_table($self -> {wrapxs}) }) {
        push @types, map $_->{type}, @{ $entry->{elts} } ;
        my $type = $entry -> {stype} || $entry->{type} ;
        push @types, $type =~/^struct\s+/?$type:"struct $type" ;
    }

    for my $entry (@{ function_table($self -> {wrapxs}) }) {
        push @types, grep { not $seen{$_}++ }
          ($entry->{return_type},
           map $_->{type}, @{ $entry->{args} })
    }

    #printf "%d types\n", scalar @types;

    for my $type (@types) {
        $type =~ s/\s*(\*\s*)+$// ;
        $type =~ s/const\s*// ;
        #$type =~ s/struct\s*// ;
        push @missing, $type unless ($self->exists($type) || $type eq 'new'  || $type eq 'private') ;
    }

    return @missing ? \@missing : undef;
}

#look for Apache/APR structures that do not exist in structure.map
my %ignore_check = map { $_,1 } qw{
module_struct cmd_how kill_conditions
regex_t regmatch_t pthread_mutex_t
unsigned void va_list ... iovec char int long const
gid_t uid_t time_t pid_t size_t
sockaddr hostent
SV
};

sub check_exists {
    my $self = shift;

    my %structures = map { my $t = $_->{type}; $t =~ s/^struct\s+// ; ($_->{type} => 1, $t => 1) } @{ structure_table($self) };
    my @missing = ();
    my %seen;
    #print Data::Dumper -> Dump ([\%structures, structure_table($self)]) ;

    for my $name (keys %{ $self->{map} }) {
        1 while $name =~ s/^\w+\s+(\w+)/$1/;
        $name =~ s/\s+\**.*$//;
        next if $seen{$name}++ or $structures{$name} or $ignore_check{$name};
        push @missing, $name;
    }

    return @missing ? \@missing : undef;
}


sub checkmaps {

    my $self = shift ;
    my %result ;
    $result{missing_functions}   = $self->{function_map} -> check ;
    $result{obsolete_functions}  = $self->{function_map} -> check_exists ;
    $result{missing_callbacks}   = $self->{callback_map} -> check ;
    $result{obsolete_callbacks}  = $self->{callback_map} -> check_exists ;
    $result{missing_structures}  = $self->{structure_map} -> check ;
    $result{obsolete_structures} = $self->{structure_map} -> check_exists ;
    $result{missing_types}       = $self-> check ;
    $result{obsolete_types}      = $self-> check_exists ;

    return \%result ;
}

sub writemaps {

    my $self = shift ;
    my $result = shift ;
    my $prefix = shift ;
    $self->{function_map}  -> write_map_file ($result -> {missing_functions}, $prefix) ;
    $self->{callback_map}  -> write_map_file ($result -> {missing_callbacks}, $prefix) ;
    $self->{structure_map} -> write_map_file ($result -> {missing_structures}, $prefix) ;
    $self -> write_map_file ($result -> {missing_types}) ;
}


sub write {
    my ($self, $fh, $newentries) = @_ ;

    my %types ;
    foreach my $type (@$newentries)
        {
        $type =~ s/\s*(\*\s*)+$// ;
        $type =~ s/const\s*// ;
        #$type =~ s/struct\s*// ;
        $types{$type} = 1 ;
        }
    
    foreach my $type (sort keys %types)
        {
        $fh -> print ("$type\t|\n") ;
        }
    }


#XXX: generate this
my %class_pools = map {
    (my $f = "mpxs_${_}_pool") =~ s/:/_/g;
    $_, $f;
} qw{
   Apache::RequestRec Apache::Connection Apache::URI
};

sub class_pool : lvalue {
    my($self, $class) = @_;
    $class_pools{$class};
}


sub h_wrap {
    my($self, $file, $code) = @_;

    $file = $self -> {wrapxs} -> h_filename_prefix . $file;

    my $h_def = uc "${file}_h";
    my $preamble = "\#ifndef $h_def\n\#define $h_def\n\n";
    my $postamble = "\n\#endif /* $h_def */\n";

    return ("$file.h", $preamble . $code . $postamble);
}

sub typedefs_code {
    my $self = shift;
    my $map = $self->get;
    my %seen;

    my $file = $self -> {wrapxs} -> h_filename_prefix . 'typedefs';
    my $h_def = uc "${file}_h";
    my $code = "";
    my @includes ;

    for (@includes, @{ $self->{INCLUDE} }) {
        $code .= qq{\#include "$_"\n}
    }

    for my $t (@{ $self->{typedefs} }) {
        next if $seen{ $t->[1] }++;
        my $class = $t->[1] ;
        $class =~ s/__$// ;
        $code .= "typedef $t->[0] * $class;\n";
    }

    $code .= "typedef void * PTR;\n";
    $code .= "#if PERL_VERSION > 5\n";
    $code .= "typedef char * PV;\n";
    $code .= "#endif\n";
    $code .= "typedef char * PVnull;\n";

    $code .= q{
#ifndef pTHX_
#define pTHX_
#endif
#ifndef aTHX_
#define aTHX_
#endif
#ifndef pTHX
#define pTHX
#endif
#ifndef aTHX
#define aTHX
#endif

#ifndef XSprePUSH
#define XSprePUSH (sp = PL_stack_base + ax - 1)
#endif

} ;

    $self->h_wrap('typedefs', $code);
}

sub sv_convert_code {
    my $self = shift;
    my $map = $self->get;
    my %seen;
    my $cnvprefix =  $self -> {wrapxs} -> my_cnv_prefix ;
    my $typemap_code = $self -> typemap_code ($cnvprefix);
    my $code = q{
    
#ifndef aTHX_
/* let it work with 5.005 */
#define aTHX_
#endif
} ;    

    while (my($ctype, $t) = each %$map) {
        my $ptype = $t -> {class} ;
        next if $self->special($ptype);
        next if ($ctype =~ /\s/)  ;
        my $class = $ptype;
        my $tmcode ;

        $ptype =~ s/:/_/g ;
        $ptype =~ s/__$// ;
        $class =~ s/::$// ;
        next if $seen{$ptype}++;

        if ($typemap_code -> {$t -> {typemapid}}) {
            my $alias;
            my $expect = "expecting an $class derived object";
            my $croak  = "argument is not a blessed reference";

            #Perl -> C
            my $define = "${cnvprefix}sv2_$ptype";

            if ($tmcode = $typemap_code -> {$t -> {typemapid}}{perl2c})
                {
                $code .= "#define $define(sv) " . eval (qq[qq[$tmcode]]) . "\n" ;
                }
            else
                {
                print "WARNING no convert code for $t -> {typemapid}\n" ;
                }
            if ($alias = $t -> {typealiases}[0]) {
                $code .= "#define ${cnvprefix}sv2_$alias $define\n\n";
            }

            #C -> Perl
            $define = "${cnvprefix}${ptype}_2obj";
            if ($tmcode = $typemap_code -> {$t -> {typemapid}}{c2perl})
                {
                $code .= "#define $define(ptr) " . eval (qq[qq[$tmcode]]) . "\n" ;
                }
            else
                {
                print "WARNING no convert code for $t -> {typemapid}\n" ;
                }
            if ($alias) {
                $code .= "#define ${cnvprefix}${alias}_2obj $define\n\n";
            }

            #Create
            $define = "${cnvprefix}${ptype}_create_obj";
            if ($tmcode = $typemap_code -> {$t -> {typemapid}}{create})
                {
                $code .= "#define $define(p,sv,rv,alloc) " . eval (qq[qq[$tmcode]]) . "\n" ;
                }

            if ($alias) {
                $code .= "#define ${cnvprefix}${alias}_2obj $define\n\n";
            }
            #Destroy
            $define = "${cnvprefix}${ptype}_free_obj";
            if ($tmcode = $typemap_code -> {$t -> {typemapid}}{destroy})
                {
                $code .= "#define $define(ptr) " . eval (qq[qq[$tmcode]]) . "\n" ;
                }

            if ($alias) {
                $code .= "#define ${cnvprefix}${alias}_2obj $define\n\n";
            }
        }
        else {
            if (($ptype =~ /^(\wV)$/) && $ptype ne 'SV') {
                my $class = $1;
                my $alias ;

                #Perl -> C
                my $define = "${cnvprefix}sv2_$ctype";

                $code .= "#define $define(sv) ($ctype)Sv$class(sv)\n\n";

                if ($alias = $t -> {typealiases}[0]) {
                    $code .= "#define ${cnvprefix}sv2_$alias $define\n\n";
                }
                #C -> Perl
                $define = "${cnvprefix}${ctype}_2obj";
                my $lcclass = lc($class) ;
                my $l = $class eq 'PV'?',0':'' ;

                $code .= "#define $define(v) sv_2mortal(newSV$lcclass(v$l))\n\n";

                if ($alias) {
                    $code .= "#define ${cnvprefix}${alias}_2obj $define\n\n";
                }
            }
        }
    }

    $code .= "#define ${cnvprefix}sv2_SV(sv) (sv)\n\n";
    $code .= "#define ${cnvprefix}SV_2obj(x) (x)\n\n";
    $code .= "#define ${cnvprefix}sv2_SVPTR(sv) (sv)\n\n";
    $code .= "#define ${cnvprefix}SVPTR_2obj(x) (x==NULL?&PL_sv_undef:sv_2mortal(SvREFCNT_inc(x)))\n\n";
    $code .= "#define ${cnvprefix}sv2_PV(sv) (SvPV(sv, PL_na))\n\n";
    $code .= "#define ${cnvprefix}PV_2obj(x) (sv_2mortal(newSVpv(x, 0)))\n\n";
    $code .= "#define ${cnvprefix}sv2_PVnull(sv) (SvOK(sv)?SvPV(sv, PL_na):NULL)\n\n";
    $code .= "#define ${cnvprefix}PVnull_2obj(x) (x==NULL?&PL_sv_undef:sv_2mortal(newSVpv(x, 0)))\n\n";
    $code .= "#define ${cnvprefix}sv2_IV(sv) SvIV(sv)\n\n";
    $code .= "#define ${cnvprefix}IV_2obj(x) sv_2mortal(newSViv(x))\n\n";
    $code .= "#define ${cnvprefix}sv2_NV(sv) SvNV(sv)\n\n";
    $code .= "#define ${cnvprefix}NV_2obj(x) sv_2mortal(newSVnv(x))\n\n";
    $code .= "#define ${cnvprefix}sv2_UV(sv) SvUV(sv)\n\n";
    $code .= "#define ${cnvprefix}UV_2obj(x) sv_2mortal(newSVuv(x))\n\n";
    $code .= "#define ${cnvprefix}sv2_PTR(sv) (SvROK(sv)?((void *)SvIV(SvRV(sv))):NULL)\n\n";
    $code .= "#define ${cnvprefix}PTR_2obj(x) (x?newRV_noinc(newSViv ((IV)x)):&PL_sv_undef)\n\n";
    $code .= "#define ${cnvprefix}sv2_CHAR(sv) (char)SvNV(sv)\n\n";
    $code .= "#define ${cnvprefix}CHAR_2obj(x) sv_2mortal(newSVnv(x))\n\n";
    $code .= "#define ${cnvprefix}sv2_AVREF(sv) (AV*)SvRV(sv)\n\n";
    $code .= "#define ${cnvprefix}AVREF_2obj(x) (x?sv_2mortal(newRV((SV*)x)):&PL_sv_undef)\n\n";
    $code .= "#define ${cnvprefix}sv2_HVREF(sv) (HV*)SvRV(sv)\n\n";
    $code .= "#define ${cnvprefix}HVREF_2obj(x) (x?sv_2mortal(newRV((SV*)x)):&PL_sv_undef)\n\n";

    $self->h_wrap('sv_convert', $code);
}

# ============================================================================

# NOTE: 'INPUT' code must not be ended with a ;


sub typemap_code

    {
    my $self = shift ;
    my $cnvprefix = shift ;

    return 
        {
        'T_MAGICHASH_SV' => 
            {
            'OUTPUT' => '    if ($var -> _perlsv) $arg = $var -> _perlsv ; else $arg = &sv_undef ;',

            'c2perl' => '(ptr->_perlsv?ptr->_perlsv:&sv_undef)',

            'INPUT' =>
q[    {
    MAGIC * mg ;
    if ((mg = mg_find (SvRV($arg), '~')))
        $var = *(($type *)(mg -> mg_ptr)) ;
    else
        croak (\"$var is not of type $type\") ;
    }
],

            'perl2c' =>
q[(SvOK(sv)?((SvROK(sv) && SvMAGICAL(SvRV(sv))) \\\\
|| (Perl_croak(aTHX_ "$croak ($expect)"),0) ? \\\\
*(($ctype **)(mg_find (SvRV(sv), '~') -> mg_ptr))  : ($ctype *)NULL):($ctype *)NULL)
],

            'create' => 
q[  sv = (SV *)newHV () ; \\\\
    p = alloc ; \\\\
    memset (p, 0, sizeof($ctype)) ; \\\\
    sv_magic ((SV *)sv, NULL, '~', (char *)&p, sizeof (p)) ; \\\\
    rv = p -> _perlsv = newRV_noinc ((SV *)sv) ; \\\\
    sv_bless (rv, gv_stashpv ("$class", 0)) ; 
    
],
            'destroy' => '    free(ptr)',
            },

        'T_PTROBJ' => 
            {
            'c2perl' => '    sv_setref_pv(sv_newmortal(), "$class", (void*)ptr)',

            'perl2c' =>
q[(SvOK(sv)?((SvROK(sv) && (SvTYPE(SvRV(sv)) == SVt_PVMG)) \\\\
|| (Perl_croak(aTHX_ "$croak ($expect)"),0) ? \\\\
($ctype *)SvIV((SV*)SvRV(sv)) : ($ctype *)NULL):($ctype *)NULL)
],

            'create' => 
q[   rv = newSViv(0) ; \\\\
    sv = newSVrv (rv, "$class") ; \\\\
    SvUPGRADE(sv, SVt_PVIV) ; \\\\
    SvGROW(sv, sizeof (*p)) ;  \\\\
    p = ($ctype *)SvPVX(sv) ;\\\\
    memset(p, 0, sizeof (*p)) ;\\\\
    SvIVX(sv) = (IV)p ;\\\\
    SvIOK_on(sv) ;\\\\
    SvPOK_on(sv) ;
],

            },
        'T_AVREF' => 
            {
            'OUTPUT' => "        \$arg = SvREFCNT_inc (${cnvprefix}AVREF_2obj(\$var));",
            'INPUT'  => "        \$var = ${cnvprefix}sv2_AVREF(\$arg)",
            },
        'T_HVREF' => 
            {
            'OUTPUT' => "        \$arg = SvREFCNT_inc (${cnvprefix}HVREF_2obj(\$var));",
            'INPUT'  => "        \$var = ${cnvprefix}sv2_HVREF(\$arg)",
            },
        'T_SVPTR' => 
            {
            'OUTPUT' => "        \$arg = SvREFCNT_inc (${cnvprefix}SVPTR_2obj(\$var));",
            'INPUT'  => "        \$var = (\$type)${cnvprefix}sv2_SVPTR(\$arg)",
            },
        'T_PVnull' => 
            {
            'OUTPUT' => "        \$arg = SvREFCNT_inc (${cnvprefix}PVnull_2obj(\$var));",
            'INPUT'  => "        \$var = (\$type)${cnvprefix}sv2_PVnull(\$arg)",
            },

        },
    }




1;
__END__
