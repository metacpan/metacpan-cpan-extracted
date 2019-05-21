package MPMinus::Helper; # $Id: Helper.pm 279 2019-05-11 22:44:41Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

MPMinus::Helper - MPMinus helper's methods. CLI user interface

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

none

=head1 DESCRIPTION

Internal functions used by mpminus program.

No public subroutines

=head2 nope, skip, yep

Internal use only!

See C<README>

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

Coming soon

=head1 SEE ALSO

L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use feature qw/say/;
use base qw/ CTK::App /;
use autouse 'Data::Dumper' => qw(Dumper); #$Data::Dumper::Deparse = 1;

use Encode; # Encode::_utf8_on();

use Term::ANSIColor qw/colored/;
use File::Spec;
use Cwd qw/getcwd/;
use Text::SimpleTable;
use File::Copy::Recursive qw(dircopy dirmove);
use CTK::Util;
use CTK::Skel;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Sys::Hostname qw/hostname/;

use MPMinus::Helper::Util qw/getApache cleanProjectName cleanServerName/;

use constant {
    HOSTNAME                => "localhost",
    PROJECT_NAME            => "Foo",
    PROJECT_TYPE_DEFAULT    => "regular",
    ADMIN_USERNAME          => "root",
    PROJECT_TYPES   => {
        regular => [qw/common regular/],
        simple  => [qw/common simple/],
        rest    => [qw/rest/],
    },
    PROJECT_SKELS   => {
        common  => "MPMinus::Skel::Common",
        regular => "MPMinus::Skel::Regular",
        simple  => "MPMinus::Skel::Simple",
        rest    => "MPMinus::Skel::REST",
    },
    PROJECT_VARS => [qw/
        PROJECT_NAME
        PROJECT_NAMEL
        PROJECT_VERSION
        PROJECT_TYPE
        SERVER_NAME
        DOCUMENT_ROOT
        SERVER_VERSION
        APACHE_VERSION
        APACHE_SIGN
        HTTPD_ROOT
        SERVER_CONFIG_FILE
        AUTHOR
        SERVER_ADMIN
        GMT
    /],
};

__PACKAGE__->register_handler(
    handler     => "usage",
    description => "Usage",
    code => sub {
### CODE:
    my ($self, $meta, @params) = @_;
    say(<<USAGE);
Usage:
    mpminus create
    mpminus create <PROJECTNAME>
    mpminus create -t simple <PROJECTNAME>
    mpminus create -t rest <PROJECTNAME>
    mpminus test
    mpminus -H
USAGE
    return 0;
});

__PACKAGE__->register_handler(
    handler     => "test",
    description => "MPMinus Testing",
    code => sub {
### CODE:
    my ($self, $meta, @params) = @_;
    unless ($self->option("tty")) {
        say STDERR "For console running only!";
        return 0;
    }
    my $host = hostname() || HOSTNAME;
    say(sprintf("Testing %s environment...\n", $host));
    my $summary = 1; # OK

    # Apache version
    my $ap2ver = getApache("APACHE_VERSION") || 0;
    if ($ap2ver) {
        yep("Apache version: %s", $ap2ver);
    } else {
        $summary = nope("Can't get Apache version");
    }

    # Allowed skels
    my $skel = new CTK::Skel ( -skels => PROJECT_SKELS );
    if (my @skels = $skel->skels) {
        yep("Allowed skeletons: %s", join(", ", @skels));
    } else {
        $summary = nope("Can't get list of skeletons");
    }

    # Summary
    if ($summary) {
        yep("All tests have been passed");
    } else {
        nope("Testing failed");
    }
    print "\n";

    return $summary;
});


__PACKAGE__->register_handler(
    handler     => "create",
    description => "Project making",
    code => sub {
### CODE:
    my ($self, $meta, @params) = @_;
    my $name = @params ? cleanProjectName(shift(@params)) : '';
    my $tty = $self->option("tty");
    my $type = $self->option("type");
    my $dir = $self->option("dir");
    my $host = hostname() || HOSTNAME;
    my $a2 = getApache();
    my %vars = (
        %$a2,
        GMT => CTK::Util::dtf("%w %MON %_D %hh:%mm:%ss %YYYY %Z", time(), 'GMT'), # scalar(gmtime)." GMT"
    );

    # Apache server check
    {
        my $ap2ver = $a2->{APACHE_VERSION} || 0;
        if ($tty && !$ap2ver) {
            print "Apache server not found!\n";
            return skip('Operation aborted')
                if $self->cli_prompt('Are you sure you want to continue?:','no') !~ /^\s*y/i;
        }
    }

    # ProjectName & ProjectNameL
    {
        unless ($name) {
            $name = $tty
                ? cleanProjectName($self->cli_prompt('Project Name:', PROJECT_NAME))
                : PROJECT_NAME;
        }
        if ($tty && $name !~ /^[A-Z]/) {
            printf "The selected name begins with a small letter: %s\n", $name;
            return skip('Operation aborted')
                if $self->cli_prompt('Are you sure you want to continue?:','no') !~ /^\s*y/i;
        }
        $vars{PROJECT_NAME} = $name;
        $vars{PROJECT_NAMEL} = lc("$name");
    }

    # Project type
    {
        my $atypes = PROJECT_TYPES;
        unless ($type) {
            $type = $tty
                ? lc($self->cli_prompt(
                        sprintf('Project type (%s):', join(", ", keys(%$atypes))),
                        PROJECT_TYPE_DEFAULT
                    ))
                : PROJECT_TYPE_DEFAULT;
        }
        return nope('Incorrect type') unless $atypes->{$type};
        $vars{PROJECT_TYPE} = $type;
    }

    # ServerName & ServerNameF & ServerNameC
    {
        my $servername = $tty
            ? cleanServerName($self->cli_prompt('Server Name (site name):',
                sprintf("%s.%s", $vars{PROJECT_NAMEL}, HOSTNAME)))
            : sprintf("%s.%s", $vars{PROJECT_NAMEL}, HOSTNAME);
        $vars{SERVER_NAME} = $servername;
    }

    # ProjectVersion
    {
        my $prjver = $tty
            ? $self->cli_prompt('Current Project Version:','1.00')
            : '1.00';
        return nope('Invalid Version ""', $prjver)
            if $prjver !~ /^\d{1,2}\.\d+/;
        $vars{PROJECT_VERSION} = $prjver;
    }

    # DocumentRoot & ModperlRoot
    {
        my $documentroot = $tty
            ? $self->cli_prompt('DocumentRoot:', File::Spec->catfile(CTK::Util::webdir, $vars{SERVER_NAME}))
            : File::Spec->catfile(CTK::Util::webdir, $vars{SERVER_NAME});
        return skip('Operation aborted') if $tty
            && $documentroot
            && (-e $documentroot)
            && $self->cli_prompt(sprintf('Directory "%s" already exists! Are you sure you want to continue?:', $documentroot),'no') !~ /^\s*y/i;
        $vars{DOCUMENT_ROOT} = $vars{MODPERL_ROOT} = $documentroot;
    }

    # Author
    {
        $vars{AUTHOR} = $tty
            ? $self->cli_prompt('Your Full Name:', 'Mr. Anonymous')
            : 'Mr. Anonymous';
    }

    # Admin
    {
        $vars{SERVER_ADMIN} = $tty
            ? $self->cli_prompt('Your email address:', sprintf('%s@%s', ADMIN_USERNAME, $host))
            : sprintf('%s@%s', ADMIN_USERNAME, $host);
    }

    # Directory
    $dir ||= $tty
        ? $self->cli_prompt('Please provide destination directory:', File::Spec->catdir(getcwd(), $vars{SERVER_NAME}))
        : File::Spec->catdir(getcwd(), $vars{SERVER_NAME});
    if (-e $dir) {
        if (!$tty) {
            return skip('Directory "%s" already exists! Operation forced aborted because silent or pipe mode is enabled', $dir);
        } else {
            return skip('Operation aborted')
                if $self->cli_prompt(sprintf('Directory "%s" already exists! Are you sure you want to continue?:', $dir),'no') !~ /^\s*y/i;
        }
    }

    # Summary
    {
        my $tbl = Text::SimpleTable->new(
                [ 25, 'PARAM' ],
                [ 57, 'VALUE / MESSAGE' ],
            );
        $tbl->row( $_, $vars{$_} ) for @{(PROJECT_VARS)};
        print("\n",colored(['cyan on_black'], "SUMMARY TABLE:"),"\n", colored(['cyan on_black'], $tbl->draw), "\n");
        return skip('Operation aborted') if $tty
            && $self->cli_prompt('All right?:','yes') !~ /^\s*y/i;
    }

    # Start building!
    {
        my $tmpdir = File::Spec->catdir($self->tempdir, $vars{SERVER_NAME});
        my $skel = new CTK::Skel (
                -name   => $name,
                -root   => $tmpdir,
                -skels  => PROJECT_SKELS,
                -debug  => $tty,
            );

        #$tmpdir = File::Spec->catdir($self->tempdir, lc($projectname));
        printf("Creating %s project %s to %s...\n\n", $type, $name, $tmpdir);

        my $skels = PROJECT_TYPES()->{$type} || [];
        foreach my $s (@$skels) {
            if ($skel->build($s, $tmpdir, {%vars})) {
                yep("The %s files have been successfully processed", $s);
            } else {
                return nope("Can't build the project to \"%s\" directory", $tmpdir);
            }
        }

        # Move to destination directory
        if (dirmove($tmpdir, $dir)) {
            yep("Project was successfully created!");
            printf("\nAll the project files was located in %s directory\n", $dir);
        } else {
            return nope("Can't move directory from \"%s\" to \"%s\": %s", $tmpdir, $dir, $!);
        }
    }

    return 1 unless $tty;

print "\n", CTK::Util::dformat(colored(['yellow on_black'], <<EOF), \%vars), "\n";
############################# Congratulations! #############################
#
#  The [PROJECT_NAME] project has been successfully created!
#
#  All the project files was located in
#
#    $dir
#
#  For instalation:
#
#    cd $dir
#    perl Makefile.PL
#    make
#    make test
#    sudo make install
#    make clean
#
#  Copy file [DOCUMENT_ROOT]/src/[SERVER_NAME].conf to Apache configuration directory, e.g:
#
#    sudo cp [DOCUMENT_ROOT]/src/[SERVER_NAME].conf [HTTPD_ROOT]/conf.d/[SERVER_NAME].conf
#
#  And run:
#
#    sudo apachectl restart
#
############################################################################
EOF

    return 1;
});

# Colored print
sub yep {
    print(colored(['green on_black'], '[  OK  ]'), ' ', sprintf(shift, @_), "\n");
    return 1;
}
sub nope {
    print(colored(['red on_black'], '[ FAIL ]'), ' ', sprintf(shift, @_), "\n");
    return 0;
}
sub skip {
    print(colored(['yellow on_black'], '[ SKIP ]'), ' ', sprintf(shift, @_), "\n");
    return 1;
}

1;

