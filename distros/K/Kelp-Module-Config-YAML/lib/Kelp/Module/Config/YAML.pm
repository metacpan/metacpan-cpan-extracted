package Kelp::Module::Config::YAML;
use Kelp::Base 'Kelp::Module::Config';
use YAML 'LoadFile';

our $VERSION = 0.01;

attr ext => 'yml';

sub load {
    my ( $self, $filename ) = @_;
    LoadFile($filename);
}

1;

__END__

=pod

=head1 NAME

Kelp::Module::Config::YAML - YAML config files for your Kelp app

=head1 SYNOPSIS

    # app.psgi
    use MyApp;

    my $app = MyApp->new( config_module => 'Config::YAML' );
    $app->run;

=head1 SEE ALSO

L<Kelp>, L<Kelp::Module>, L<Kelp::Module::Config>

=head1 AUTHOR

Stefan Geneshky minimal@cpan.org

=head1 LICENSE

Perl

=cut
