package Language::XS;

use strict 'subs';
use Carp;
use Config;
use File::Spec;
#use ExtUtils::MakeMaker; # argh, but knows useful info we can't deduce otherwise!

require Exporter;

#BEGIN { $^W=0 } # I'm fed up with bogus and unnecessary warnings nobody can turn off.

@ISA = qw(Exporter);

@EXPORT = ();
@EXPORT_OK = ();
%EXPORT_TAGS = ();
$VERSION = 0.02;

=head1 NAME

Language::XS - Write XS code on the fly and load it dynamically.

=head1 SYNOPSIS

  use Language::XS;

=head1 DESCRIPTION

This module allows C & XS-code creation "on-the-fly", i.e. while your
script is running.

Here is a very simple example:

 # create a Language::XS-object
 my $xs = new Language::XS cachedir => undef;
 # add plain C to the header
 $xs->hdr("#include <stdio.h>");
 # add a c function (not using xs syntax)
 $xs->cfun('printf ("I was called with %d arguments\n", items);');

 # now compile and find the code-reference
 my $coderef = $xs->find;
 # Now call it
 $coderef->(1, "Zwei", 1/3);

=head1 METHODS

=cut

#my $xsloader = eval { require XSLoader };
#$xsloader or require DynaLoader;

# *NIX-specifix
my $uid = "XUzNaIcQeUfExxIaD0000";
sub next_uid { ++$uid }

# *NIX-specific
my $default_cache = "$ENV{HOME}/.perl-xs-cache";

my %tmpdirs;

# this is *NIX-specific, and rather clumsy
sub tmpdir_create {
   my $self = shift;
   my $prefix = ($ENV{TMPDIR}||"/tmp")."/language-xs-";
   my $suffix = "T${$}000";
   $suffix++ while !mkdir "$prefix$suffix", 0700;
   $tmpdirs{"$prefix$suffix"} = 1;
   "$prefix$suffix";
}

sub tmpdir_cleanup {
   my $dir = shift;
   return unless exists $tmpdirs{$dir};
   if (opendir DIR, $dir) {
      while (my $name = readdir DIR) {
         unlink "$dir/$name";
      }
      closedir DIR;
   }
   rmdir $dir;
   delete $tmpdirs{$dir};
}

END {
   for $dir (keys %tmpdirs) {
      tmpdir_cleanup $dir;
   }
}

sub sanitize_id($) {
   my $id = shift;
   $id =~ y{0-9a-zA-Z\-_.:/\\}{}cd;
   $id;
}

=head2 new attr => value, ...

Creates a new Language::XS object. Known attributes are:

 id		a unique id that woill be shared among all modules
 cachedir	the common directory where shared objects should be cached.
                set to undef when you want to disable sharing (must be
                an  absolute path)

Default values will be supplied when necessary. Two common idioms are:

 $xs = new Language::XS;			# caching enabled
 $xs = new Language::XS cachedir => undef;	# caching disabled

=cut

# id = unique id (for caching)
sub new {
   my $class = shift;
   $self = bless {
      id => next_uid(),
      cachedir => $default_cache,
      dirty => 0,
      @_
   };
   $self->{id} = sanitize_id $self->{id};
   $self->{package} = "language_xs_$self->{id}";
   $self->{sofile} ||= File::Spec->catfile($self->{cachedir}, "$self->{id}.$Config{dlext}") if $self->{cachedir};
   $self;
}

sub DESTROY {
   my $self = shift;
   tmpdir_cleanup($self->{tmpdir});
}

=head2 cached

Returns true when as shared object with the given id already exists. This obviously only makes sense when
you gave the module a unique id.

=cut

sub cached($) {
   my $self = shift;
   $self->{cachedir} && -e $self->{sofile};
}

# prepend linenumber-heuristic
sub _lineno($$) {
   my ($code, $id) = @_;
   my @c = caller(1);
   my $line = $c[2]*1;
   $id = $c[3] unless $id;
   $id = sanitize_id $id;
   $line++ if $code =~ /\n/; # assume here document
   "\n#line $line \"$id\"\n".$code."\n";
}

=head2 hdr sourcecode, [id]

Add C<sourcecode> to the header portion. Similar to the header portion of
an XS module, you can insert any valid C-code here. Most often you'd add
some include directives, though.

C<id> can be used to identify this portion (for error messages).

=cut

# add simple C code as header
sub hdr($$$) {
   my ($self, $code, $id) = @_;
   $self->{dirty} = 1;
   $self->{hdr} .= _lineno($code, $id);
}

=head2 cfun functionbody, [id], [prototype]

Adds a XS function whose body is given in C<functionbody>. Unlike
XS, you have to do argument processing (i.e. fiddling with C<ST(0)>)
yourself. C<id> specifies the function name (for C<find()> or error
messages), and can be omitted (which results in a default name).

C<prototype> is an optional string that specifies the perl
protoype. Remember that only the parser will evaluate prototypes.

=cut

# add a function body written in C
sub cfun($$$$) {
   my ($self, $body, $id, $prototype) = @_;
   $self->{dirty} = 1;
   $self->{fun}{$id||"default"} = [_lineno($body, $id), $prototype];
}

=head2 xsfun xs-source

Similar to C<cfun>, but is able to parse normal XS syntax (most of it,
that is).  Pity that I haven't yet implemented this function, since that
would require serious recoding of C<xsubpp>.

=cut

# add a function body written in XS
sub xsfun($$$) {
   croak "add_xsfun not yet, implemented, use add_cfun isntead";
   my ($self, $body) = @_;
}

=head2 uselib lib...

Link against all the libraries given as arguments. The libraries should be
specified as strings of the form C<-llibrary>. Additional search paths can
be given using C<-L/path/to/libs>. See L<ExtUtils::Liblist>.

=cut

sub uselib {
   my $self = shift;
   $self->{libs} .= " @_";
}

=head2 incpath path...

Add additional include paths. These paths are prepended to the other
include paths.

=cut

sub incpath {
   my $self = shift;
   for  (@_) {
      $self->{incpath} .= " -I$_";
   }
}

sub gen_cfile {
   my $self = shift;
   my $boot;
   open CFILE, ">".$self->{cfile} or croak "$self->{cfile}: $!";
   print CFILE "#include \"EXTERN.h\"\n",
               "#include \"perl.h\"\n",
               "#include \"XSUB.h\"\n",
               $self->{hdr}."\n";
   while (my ($id, $def) = each %{$self->{fun}}) {
      my ($body, $prot) = @$def;
      $id = sanitize_id $id;
      my $fun = "$self->{package}_$id";
      print CFILE "XS($fun)\n{\n   dXSARGS;\n\n$body\n\n   XSRETURN_EMPTY;\n}\n\n";
      $proto = $proto ? "newXSproto(0, $fun, __FILE__, \"$prot\")"
                      : "newXS(0, $fun, __FILE__)";
      $boot .= "   hv_store (hv, \"$id\", ".(length $id).", newRV_noinc ((SV *)$proto), 0);\n";   
   }

   print CFILE "XS(boot_$self->{package})\n{\n   dXSARGS;\n   HV *hv = (HV *)SvRV (ST (0));\n$boot}\n\n";
   close CFILE;
}

# somewhat os-specific
sub run_cmd {
   my ($wd, $cmd) = @_;
   if (0 == open CMD, "-|") {
      open STDERR, ">&STDOUT" or exit 1;
      chdir $wd or die "unable to cd to '$wd': $!\n";
      exec $Config{sh}, "-c", $cmd;
      exit 127; # unreachable
   }
   #open CMD, "$cmd 2>&1 |" or croak "unable to execute '$cmd': $!";
   local $/;
   $cmd = <CMD>;
   ((close CMD), $cmd);
}

# very os-specific(!)
sub gen_sofile {
   my $self = shift;
   local $^W = 0; # perl is rather borken
   ($self->{ofile} = $self->{cfile}) =~ s/\.c$/$Config{_o}/;
   my ($ok, $msg) = run_cmd $self->{tmpdir},
                            "$Config{cc} -c $self->{incpath} $Config{ccflags} $Config{optimize} $Config{large} ".
                            "$Config{split} $Config{cccdlflags} $self->{cflags} -I$Config{archlibexp}/CORE $self->{cfile}";
   $self->{messages} .= $msg;
   $ok &&= -e $self->{ofile};
   if ($ok) {
      # perl_archive is os-specific(!) also export_list(!)
      if ($self->{libs}) {
         require ExtUtils::Liblist;
         @$self{'extralibs', 'bsloadlibs', 'ldloadlibs', 'ld_run_path'} =
            ExtUtils::Liblist::ext($self, $self->{libs}, 0);
      }
      ($ok, $msg) = run_cmd $self->{tmpdir},
                            "LD_RUN_PATH=\"$self->{ld_run_path}\" $Config{ld} -o $self->{sofile} ".
                            "$Config{lddlflags} $self->{ofile} $self->{otherldflags} $self->{perl_archive} ".
                            "$self->{ldloadlibs} $self->{export_list}";
      $ok &&= -e $self->{sofile};
      $self->{messages} .= $msg;
      if ($ok) {
         chmod 0755, $self->{sofile};
      }
   }
   unlink $ofile;
   $self->{dirty} = 0;
   $ok;
}

=head2 gen

Create the shared object file. This method is called automatically by
C<load> and even by C<find>. This function returns a truth status and
fills the messages attribute (see C<messages>) with any compiler/linker
warnings or errors.

=cut

# generate code (& optionally cache)
sub gen($) {
   my $self = shift;
   $self->{tmpdir} ||= tmpdir_create();
   $self->{messages} = "";
   delete $self->{loaded};
   $self->{sofile} ||= File::Spec->catfile($self->{tmpdir}, "$self->{id}.$Config{dlext}") unless $self->{sofile};
   $self->{cfile}  ||= File::Spec->catfile($self->{tmpdir}, "$self->{id}.c");
   if ($self->{cachdir} && ! -d $self->{cachedir}) {
      mkdir $self->{cachedir},0755 or croak "unable to create '$self->{cachedir}': $!";
   }
   my $ok = $self->gen_cfile && $self->gen_sofile;
   unlink $self->{cfile};
   tmpdir_cleanup($self->{tmpdir}) if $self->{cachedir};
   $ok;
}

=head2 messages

Returns the compiler messages (created & updated by C<gen>).

=cut

sub messages {
   shift->{messages};
}

=head2 load

Tries to load the shared object, generating it if necessary. Returns a
truth status.

=cut

sub load {
   my $self = shift;
   if (!$self->{loaded}) {
      if (!$self->{sofile} || $self->{dirty}) {
         $self->gen or return 0;
      }
      require DynaLoader;
      $self->{dl_lib} = DynaLoader::dl_load_file($self->{sofile}) or croak "unable to load $self->{sofile}";
      $self->{dl_boot} = DynaLoader::dl_find_symbol($self->{dl_lib}, "boot_$self->{package}") or croak "no entry point found";
      $self->{dl_boot_cv} = DynaLoader::dl_install_xsub(__PACKAGE__."boot_$self->{package}", $self->{dl_boot});
      $self->{dl_hash} = { };
      $self->{dl_boot_cv}->($self->{dl_hash});
      $self->{loaded} = 1;
   }
   $self->{loaded};
}

=head2 find [id]

Find the function (either xs or c) with id C<id> and return a code-ref to
it. If C<id> is omitted, the default function (see C<cfun>) is returned
instead. If no shared object is loaded, calls C<load>.

=cut

sub find {
   my ($self, $fun) = @_;
   $self->load unless $self->{loaded};
   $self->{dl_hash}{$fun||"default"};
}

=head1 BUGS/PROBLEMS

Requires a C compiler (or even worse: the same C compiler perl was compiled with).

Does (most probably) not work on many os's, especially non-unix ones.

You cannot yet use normal XS syntax.

Line number handling could be better.

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>.

=head1 SEE ALSO

perl(1).

=cut

# compatibility cruft for ExtUtils::Liblist

sub lsdir {
   my($self) = shift;
   my($dir, $regex) = @_;
   my(@ls);
   require DirHandle;
   my $dh = new DirHandle;
   $dh->open($dir || ".") or return ();
   @ls = $dh->read;
   $dh->close;
   @ls = grep(/$regex/, @ls) if $regex;
   @ls;
}

1;

