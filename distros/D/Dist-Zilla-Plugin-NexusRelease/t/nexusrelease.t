use strict;
use warnings;
use Test::More 1.00;

use File::Spec ();
use Test::DZil qw(Builder simple_ini);
use Test::Fatal qw(exception);
use Dist::Zilla::Plugin::NexusRelease;

#---------------------------------------------------------------------
# Install a fake upload_file method for testing purposes:
sub Dist::Zilla::Plugin::NexusRelease::_Uploader::upload_file {
    my ( $self, $archive ) = @_;

    $self->log("Nexus $_ is $self->{$_}")
        for qw(nexus_URL username password repository group artefact version);
    $self->log("Uploading $archive") if -f $archive;
}

#---------------------------------------------------------------------
# Create a Builder with a simple configuration:
sub build_tzil {
    Builder->from_config(
        { dist_root => 'corpus/DZT' },
        {   add_files =>
                { 'source/dist.ini' => simple_ini( 'GatherDir', @_ ), },
        },
    );
}

#---------------------------------------------------------------------
# Set responses for the username and password prompts:
sub set_responses {
    my $chrome = shift->chrome;
    $chrome->set_response_for( 'Nexus username: ', shift );
    $chrome->set_response_for( 'Nexus password: ', shift );
    $chrome->set_response_for( 'Nexus group: ',    shift );
}

#---------------------------------------------------------------------
# Config from user input:
{
    my $tzil = build_tzil( 'NexusRelease', 'FakeRelease', );

    set_responses( $tzil, qw(user password group) );

    $tzil->release;

    my $msgs = $tzil->log_messages;

    #ok( 0, "Log messages (User input config): " . join( "\n", @$msgs ) );

    ok( grep( {/Nexus username is user/} @$msgs ),     "entered username" );
    ok( grep( {/Nexus password is password/} @$msgs ), "entered password" );
    ok( grep( {/Nexus group is group/} @$msgs ),       "entered group" );
    ok( grep( {/Uploading.*DZT-Sample/} @$msgs ),
        "uploaded archive manually" );
    ok( grep( {/fake release happen/i} @$msgs ),
        "releasing continues after manual upload",
    );
}

#---------------------------------------------------------------------
# No config at all:
{
    my $tzil = build_tzil( 'NexusRelease', 'FakeRelease', );

    # Pretend user just hits Enter at the prompts:
    set_responses( $tzil, '', '', '' );

    like(
        exception { $tzil->release },
        qr/Missing attributes/,
        "release without credentials fails"
    );

    my $msgs = $tzil->log_messages;

    #ok( 0, "Log messages (No config): " . join( "\n", @$msgs ) );

    ok( grep( {/You need to supply a username/} @$msgs ),
        "insist on username" );
    ok( !grep( {/Uploading.*DZT-Sample/} @$msgs ),
        "no upload without credentials" );
    ok( !grep( {/fake release happen/i} @$msgs ),
        "no release without credentials"
    );
}

#---------------------------------------------------------------------
# No config at all, but enter username:
{
    my $tzil = build_tzil( 'NexusRelease', 'FakeRelease' );

    # Pretend user just hits Enter at the password prompt:
    set_responses( $tzil, 'user', '', 'BRAD' );

    like(
        exception { $tzil->release },
        qr/Missing attributes.*password/,
        "release without password fails"
    );

    my $msgs = $tzil->log_messages;

    #ok( 0, "Log messages (username only entered): " . join( "\n", @$msgs ) );

    ok( grep( {/You need to supply a password/} @$msgs ),
        "insist on password" );
    ok( !grep( {/Uploading.*DZT-Sample/} @$msgs ),
        "no upload without password" );
    ok( !grep( {/fake release happen/i} @$msgs ),
        "no release without password" );
}

done_testing;
