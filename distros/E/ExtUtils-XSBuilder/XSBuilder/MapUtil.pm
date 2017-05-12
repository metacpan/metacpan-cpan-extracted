package ExtUtils::XSBuilder::MapUtil;

use strict;
use warnings;
use Exporter ();
use Data::Dumper ;
use IO::Handle ;
use ExtUtils::XSBuilder::TypeMap ;

our @EXPORT_OK = qw(list_first disabled_reason
                    function_table structure_table 
                    callback_table callback_hash
                    );

our @ISA = qw(Exporter);

my %disabled_map = (
    '!' => 'disabled or not yet implemented',
    '~' => 'implemented but not auto-generated',
    '-' => 'likely never be available to Perl',
    '>' => '"private" to apache',
    '?' => 'unclassified',
    '+' => 'automaticly added',
);

# ============================================================================

my $function_table = [];

sub function_table {
    return $function_table if @$function_table;

    my $parsesource = shift -> parsesource_objects ;

    $function_table = [] ;

    foreach my $src (@$parsesource) {
        require $src -> pm_path ('FunctionTable.pm') ;
no strict ;
        push @$function_table, @${$src -> package . '::FunctionTable'} ;
use strict ;
    }

    return $function_table;
}

# ============================================================================

my $callback_table = [];

sub callback_table {
    return $callback_table if @$callback_table;
    my $parsesource = shift -> parsesource_objects ;

    $callback_table = [] ;

    foreach my $src (@$parsesource) {
        require $src -> pm_path ('CallbackTable.pm') ;
no strict ;
        push @$callback_table, @${$src -> package . '::CallbackTable'} ;
use strict ;
    }
    return $callback_table;
}


# ============================================================================

my $callback_hash ;

sub callback_hash {
    return $callback_hash if $callback_hash ;

    my %callbacks = map { $_->{name}, $_ } @{ callback_table(shift) };

    $callback_hash = \%callbacks ;
}

# ============================================================================

my $structure_table = [];

sub structure_table {
    return $structure_table if @$structure_table;
    $structure_table = [] ;

    my $parsesource = shift -> parsesource_objects ;
    foreach my $src (@$parsesource) {
        require $src -> pm_path ('StructureTable.pm') ; 
no strict ;
        push @$structure_table, @${$src -> package . '::StructureTable'} ;
use strict ;
    }
    return $structure_table;
}

# ============================================================================

sub disabled_reason {
    $disabled_map{+shift} || 'unknown';
}


# ============================================================================

sub list_first (&@) {
    my $code = shift;

    for (@_) {
        return $_ if $code->();
    }

    undef;
}

# ============================================================================

package ExtUtils::XSBuilder::MapBase;

*function_table = \&ExtUtils::XSBuilder::function_table;
*structure_table = \&ExtUtils::XSBuilder::structure_table;

sub readline {
    my $fh = shift;

    while (<$fh>) {
        chomp;
        s/^\s+//; s/\s+$//;
        s/^\#.*//;
        s/\s*\#.*//;

        next unless $_;

        if (s:\\$::) {
            my $cur = $_;
            $_ = $cur . $fh->readline;
            return $_;
        }

        return $_;
    }
}

my $map_classes = join '|', qw(type structure function callback);

sub map_files {
    my $self = shift;
    my $package = ref($self) || $self;

    my($wanted) = $package =~ /($map_classes)/io;

    my(@dirs) = ($self -> {wrapxs} -> xs_map_dir(), $self -> {wrapxs} -> xs_glue_dirs());

    my @files;

    my @searchdirs = map { -d "$_/maps" ? "$_/maps" : $_ } @dirs ;
    for my $dir (@searchdirs) {
        opendir my $dh, $dir or warn "opendir $dir: $!";

        for (readdir $dh) {
            next unless /\.map$/;

            my $file = "$dir/$_";

            if ($wanted) {
                next unless $file =~ /$wanted/i;
            }

            #print "$package => $file\n";
            push @files, $file;
        }

        closedir $dh;
    }

    print 'WARNING: No *_' . lc($wanted) . ".map file found in @searchdirs\n" if (!@files) ;
    return @files;
}

sub new_map_file {
    my $self = shift;
    my $package = ref($self) || $self;

    my($wanted) = $package =~ /($map_classes)/io;

    my(@dirs) = ($self -> {wrapxs} -> xs_map_dir(), $self -> {wrapxs} -> xs_glue_dirs());

    my @files;

    my @searchdirs = map { -d "$_/maps" ? "$_/maps" : $_ } @dirs ;
    

    if (!@searchdirs) 
        {
        print "WARNING: No maps directory found\n" ;
        return undef ;
        }

    
    return $searchdirs[0] . '/new_' . lc($wanted) . '.map' ;
}


sub parse_keywords {
    my($self, $line) = @_;
    my %words;

    for my $pair (split /\s+/, $line) {
        my($key, $val) = split /=/, $pair;

        unless ($key and $val) {
            die "parse error ($ExtUtils::XSBuilder::MapFile line $.)";
        }

        $words{$key} = $val;
    }

    %words;
}

sub parse_map_files {
    my($self) = @_;

    my $map = {};

    for my $file (map_files($self)) {
        print "Parse $file...\n" ;
        open my $fh, $file or die "open $file: $!";
        local $ExtUtils::XSBuilder::MapFile = $file;
        bless $fh, __PACKAGE__;
        $self->parse($fh, $map);
        close $fh;
    }

    return $map;
}

sub write_map_file {
    my($self, $newentries, $prefix) = @_;

    return if (!$newentries || !@$newentries) ;

    my $file = $self -> new_map_file or die ;

    print "Write $file...\n" ;
    open my $fh, '>>', $file or die "open $file: $!";
    local $ExtUtils::XSBuilder::MapFile = $file;
    #bless $fh, __PACKAGE__;

    $fh -> print ( "\n### Added " . scalar(localtime) . " ###\n\n" );

    $self->write($fh,  $newentries, $prefix);
    close $fh;
}


1;
__END__
