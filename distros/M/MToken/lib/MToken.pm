package MToken; # $Id: MToken.pm 75 2019-06-19 15:23:53Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MToken - Tokens processing system (Security)

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    mtoken init MyToken
    perl Makefile.PL
    make init
    make help

=head1 DESCRIPTION

Tokens processing system (Security)

=over 4

=item STEP1

Create a token device

    cd /my/token/dir
    mtoken init MyToken

=item STEP2

Initialize the MyToken device

    perl Makefile.PL
    make init

Get help page

    make help

Test the device

    make test

=item STEP3

Generate GPG key pair

    make gengpgkey

=item STEP4

Add file to device

    make add

Update file on device

    make update

Delete file from device

    make delete

Show file list on device

    make show

=item STEP5

Backup current token device to server

    make backup

Show list of all available backups on server

    make list

Show information about last backup stored on server

    make info

=item STEP6

Restore token device from server backup

    make restore

=item STEP7

Cleaning the device (delete all temporary files)

    make clean

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<LWP>, L<CTK>, C<openssl>, C<gnupg>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

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

use vars qw/ $VERSION /;
$VERSION = "1.02";

use feature qw/say/;
use Carp;
use Cwd qw/getcwd/;
use CTK::Skel;
use MToken::Const;
use MToken::Util qw/explain red yellow /;
use MToken::Config;

use base qw/ CTK::App /;

__PACKAGE__->register_handler(
    handler     => "test",
    description => "MToken testing (internal use only)",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;

    if ($self->verbosemode) {
        say("CLI arguments: ", join("; ",@arguments) || yellow('none') );
        say("Meta: ", explain($meta));
        say("CTK object: ", explain($self));
        say("App handlers: ", join(", ", $self->list_handlers));
    } else {
        say STDERR red("Incorrect arguments!");
        say STDERR "Usage:";
        say STDERR "  mtoken test -v -- for show app information";
        return 0;
    }

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "init",
    description => "Initialize token device",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $prj = shift(@arguments);
    my $dir  = $self->option("directory") || getcwd();

    # Project name
    $prj //= $self->project;
    $prj = lc($prj);
    $prj =~ s/\s+//g;
    $prj =~ s/[^a-z0-9]//g;
    $prj ||= $self->project;
    if ($prj =~ /^\d/) {
        $self->error("The project name must not begin with numbers. Choose another name consisting mainly of letters of the Latin alphabet");
        return 0;
    }

    my $skel = new CTK::Skel (
            -name   => $prj,
            -root   => $dir,
            -skels  => {
                        device => 'MToken::DeviceSkel',
                    },
            -vars   => {
                    PROJECT         => $prj,
                    PROJECTNAME     => $prj,
                    NAME            => ($prj eq $self->project) ? "MToken::Device" : sprintf("%s::Device", ucfirst($prj)),
                    DISTNAME        => $prj,
                    GPGBIN          => GPGBIN,
                    OPENSSLBIN      => OPENSSLBIN,
                    MTOKEN_VERSION  => $VERSION,
                    CONFFILEONLY    => MToken::Config::GLOBAL_CONF_FILE(),
                },
            -debug  => $self->debugmode,
        );
    #say("Skel object: ", explain($skel));
    printf("Initializing device \"%s\"...\n", $prj);
    my %vars = (
            PACKAGE => __PACKAGE__,
            VERSION => $VERSION,
        );
    if ($skel->build("device", $dir, {%vars})) {
        say "Done.";
    } else {
        say "Fail.";
        $self->error(sprintf("Can't build the device to \"%s\" directory", $dir));
        return 0;
    }
    return 1;
});

1;

__END__
