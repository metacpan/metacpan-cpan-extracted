use strict;
use warnings;

package Footprintless::Plugin::Database::SqlShellAdapter;
$Footprintless::Plugin::Database::SqlShellAdapter::VERSION = '1.04';
# ABSTRACT: An adaptor to SQL::Shell
# PODNAME: Footprintless::Plugin::Database::SqlShellAdapter

use Exporter qw(import);
use Footprintless::Util qw(slurp);
use SQL::Shell;
use Term::ReadLine;

our @EXPORT_OK = qw(
    sql_shell
);

use constant HISTORY_FILE => '~/.footprintless/.sqlsh_history';

sub _help {
    my ($self) = @_;
    use Config;
    require Pod::Select;
    my $pager = $Config{pager};
    my $have_pager = ( $pager && -f $pager && -x _ );

    my $helptext = "SQL Shell\n";

    {
        local ( *STDOUT, $^W );
        require Pod::Select;
        require IO::Scalar;
        tie( *STDOUT, 'IO::Scalar', \$helptext );
        Pod::Select::podselect( { -sections => ['COMMANDS'] }, $INC{'SQL/Shell.pm'} );
        Pod::Select::podselect( { -sections => ['COMMANDS ADDED BY SQLSH'] }, $0 );
        untie(*STDOUT);
        $helptext =~ s/=head1.*?\n//sg;
        $helptext =~ s/\n\n/\n/g;
    }

    if ($have_pager) {
        local ( *STDOUT, $^W );
        open( my $pager, '|', $pager );
        print( $pager $helptext );
        close($pager);
    }
    else {
        print $helptext;
    }

    return 1;
}

sub _parse_script {
    my ($script) = @_;

    # should do a better job, but...
    return map {
        my $line = $_;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        $line
    } split( /;/, $script );
}

sub sql_shell {
    my ( $connection_string, $username, $password, @args ) = @_;

    my $sqlsh = new SQL::Shell( { Verbose => 1 } );
    $sqlsh->connect( $connection_string, $username, $password );

    if ( -t STDIN ) {    ## no critic
        $sqlsh->set( 'Interactive', 1 );
        ( $ENV{EDITOR} ) =
              $ENV{PERL_READLINE_MODE} ? $ENV{PERL_READLINE_MODE}
            : $ENV{SHELLOPTS}          ? $ENV{SHELLOPTS} =~ /\b(emacs|vi)\b/
            :                            $ENV{EDITOR};

        my $term        = Term::ReadLine->new("SQL Shell (fpl)");
        my $autohistory = $term->Features()->{autohistory};
        my $ornaments   = $term->ornaments();
        if ( defined($ornaments) && $ornaments ne ',,,' ) {
            $sqlsh->set( 'NULL', "\x1B[1mNULL\x1B[0m" );
        }

        $sqlsh->set(
            'GetHistory',
            sub {
                return [ $term->GetHistory() ];
            }
        );
        $sqlsh->set(
            'SetHistory',
            sub {
                my $history = shift;
                $term->SetHistory(@$history);
            }
        );
        $sqlsh->set(
            'AddHistory',
            sub {
                my $cmd = shift;
                $term->addhistory($cmd) unless $autohistory;
            }
        );

        my $quit = 0;
        $sqlsh->install_cmds(
            {   qr/^help|\?$/ => \&_help,
                qr/^reload$/  => sub {
                    my ($self) = @_;
                    my $settings = $self->{settings};
                    if ( $settings->{Interactive} ) {
                        exec( $^X, $0, @args );
                        exit 0;
                    }
                    return 1;
                },
                qr/^(cat|more|less) (.+)/ => sub {
                    my ( $self, $pager, $file ) = @_;
                    return system( $pager, $file ) == 0;
                },
                qr/^(?:exit|quit|bye|\w+\s+off)$/i => sub {
                    my ($sqlsh) = @_;
                    $sqlsh->disconnect();
                    $quit = 1;
                }
            }
        );

        $sqlsh->load_history(HISTORY_FILE) if ( -f HISTORY_FILE );

        local $_;
        my $prompt = "SQL> ";
        while ( defined( $_ = $term->readline($prompt) ) ) {
            eval { $sqlsh->execute_cmd($_); };
            print("Error: $@") if ($@);
            last if ($quit);
        }

        $sqlsh->save_history(HISTORY_FILE);
    }
    else {
        my $script = slurp();
        $sqlsh->execute_cmd($_) foreach _parse_script($script);
    }
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::SqlShellAdapter - An adaptor to SQL::Shell

=head1 VERSION

version 1.04

=head1 SYNOPSIS

    # Standard way of getting an overlay
    use Footprintless::Plugin::Database::SqlShellAdapter qw(sql_shell);
    sql_shell('DBI:CSV:f_dir=/tmp');

=head1 DESCRIPTION

Provides a vendor independent client implementation using L<SQL::Shell>. 

=head1 FUNCTIONS

=head2 sql_shell($connection_string, $username, $password, %options)

Executes the shell.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=item *

L<SQL::Shell|SQL::Shell>

=back

=cut
