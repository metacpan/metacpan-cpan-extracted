package INI::ReadPath;
$INI::ReadPath::VERSION = '1';
use strict;
use warnings;
use Config::INI::Reader;
use Mouse;
use Template;

=head1 NAME

INI::ReadPath - In Jenkins grep dist.ini config file and assign something 
inside of the config to an environment variable.

=head1 USAGE

Let's say your ini file is dist.ini

And we want to package name

 PAKCAGE_NAME=$(read_ini.pl --file dist.ini --path ini.name )

=cut

has file => (
    is  => "ro",
    isa => "Str",
);

has string => (
    is  => "ro",
    isa => "Str",
);

has config => (
    is         => "ro",
    isa        => "HashRef",
    lazy_build => 1,
);

sub _build_config {
    my $self = shift;
    my $ini_str = $self->from_file || $self->string
      or die "No data";
    my $config = Config::INI::Reader->read_string($ini_str);
    $config->{ini} = delete $config->{_};
    return $config;
}

sub from_file {
    my $self = shift;
    my $file = $self->file
      or return;
    return if !-f $file;
    open my $FH, "<", $file
      or return;
    local $/;
    my $string = <$FH>;
    close $FH;
    return $string;
}

sub get {
    my $self   = shift;
    my $config = $self->config;
    my $path   = shift
      or return $config;
    my $tt    = Template->new;
    my $value = q{};
    $tt->process( \"[%$path%]", $config, \$value )
        or die $tt->error;
    return $value;
}

1;
