package Kelp::Module::Config::General;
use strict;
use 5.008_005;
use Kelp::Base 'Kelp::Module::Config';
use Config::General;

our $VERSION = '0.04';

attr ext => 'conf';

sub load {
    my ( $self, $filename ) = @_;

    my $conf = Config::General->new(
        -ConfigFile      => $filename,
        -ForceArray      => 1,
        -IncludeAgain    => 1,
        -InterPolateVars => 1,
        -IncludeRelative => 1,
    );
    my %config = $conf->getall;

    # Hack for using default Log::Dispatch
    if ( exists $config{modules_init}{Logger} ) {
        my $outputs = $config{modules_init}{Logger}{outputs};
        
        my @outputs = map {
            my ( $k, $v ) = ($_, $outputs->{$_});
            my @res;
            push @res, ( ref $v eq 'ARRAY' ) ? map { [ $k, %$_ ] } @$v
                     : ( ref $v eq 'HASH'  ) ? [ $k, %$v ]
                     :                         [];            
            @res;
        } keys %$outputs;
        $config{modules_init}{Logger}{outputs} = \@outputs;        
    }
    
    return \%config;
}

1;
__END__

=encoding utf-8

=head1 NAME

Kelp::Module::Config::General - L<Config::General> as config module for your Kelp applications.

=head1 SYNOPSIS

    # app.psgi
    use MyApp;
    my $app = MyApp->new( config_module => 'Config::General' );
    $app->run;

=head1 DESCRIPTION

This module provides support of L<Config::General> as your C<Kelp::Module::Config> module.

L<Config::General> module is loaded with following configuration options:

    -ForceArray      => 1,
    -IncludeAgain    => 1,
    -InterPolateVars => 1,
    -IncludeRelative => 1,

Because L<Config::General> provides key/value interface you are not able to create array of arrays for your default L<Kelp::Module::Logger> configuration. This module does it for you but only in this situation.

Example:

    modules = [ Logger ]
    
    <modules_init Logger>
      <outputs Screen>
         name      debug
         min_level debug
         newline   1
         binmode   :encoding(UTF-8)
      </outputs>
      <outputs Screen>
         name      error
         min_level error
         newline   1
         stderr    1
         binmode   :encoding(UTF-8)
      </outputs>
    </modules_init>

    becomes:

    {
        modules => [ 'Logger' ],
    },
    {
        modules_init => {
            Logger => [
                [
                    'Screen',
                    name      => 'debug',
                    min_level => 'debug',
                    newline   => 1
                    binmode   => ':encoding(UTF-8)'
                ], [
                    'Screen',
                    name      => 'error',
                    min_level => 'error',
                    newline   => 1,
                    stderr    => 1,
                    binmode   => ':encoding(UTF-8)'
                ]
            ],
        }
    }


=head1 AUTHOR

Konstantin Yakunin E<lt>twinhooker@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Konstantin Yakunin

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
