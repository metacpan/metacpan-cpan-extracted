package File::Stubb;
use 5.016;
our $VERSION = '0.03';
use strict;
use warnings;

use File::Basename;
use Getopt::Long;

use File::Stubb::Home;
use File::Stubb::Render;

use constant {
    MODE_DEFAULT => 0,
    MODE_BATCH   => 1,
    MODE_LIST    => 2,
};

my $PRGNAM = 'stubb';
my $PRGVER = $VERSION;

my $HELP = <<"HERE";
$PRGNAM - $PRGVER
Usage:
  $0 [options] file template
  $0 [options] file.template
  $0 [options] -t template file ...
  $0 [options] -l template

Options:
  -d|--template-dir=<dir>    Specify template directory
  -t|--template=<template>   Specify template for batch file creation
  -s|--substitute=<params>   Provide stubb substitution parameters
  -a|--hidden                Toggle whether to render hidden files or not
  -A|--no-hidden
  -c|--copy-perms            Toggle whether to copy template permissions or not
  -C|--no-copy-perms
  -w|--follow-symlinks       Toggle whether to follow symlinks or not
  -W|--no-follow-symlinks
  -U|--no-defaults           Disable the use of default substitution parameters
  -I|--no-config             Ignore template's configuration file
  -l|--list                  List substitution targets in template
  -q|--quiet                 Disbale informative output

  -h|--help      Display this help message
  -v|--version   Display version/copyright info

Consults the $PRGNAM(1) manual for more documentation.
HERE

my $VER_MSG = <<"HERE";
$PRGNAM - $PRGVER

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
HERE

sub _subst_params {

    my ($str) = @_;

    my $params = {};

    # Temporarily hide escaped commas.
    $str =~ s/\\,/\x{fffd}/g;

    my @kvs = grep { /=>/ } split /,/, $str;

    for my $kv (@kvs) {

        my ($k, $v) = split /=>/, $kv, 2;
        $k =~ s/^\s+|\s+$//g;
        $v =~ s/^\s+|\s+$//g;

        unless ($k =~ /^[a-zA-Z0-9_]+$/) {
            die "'$k' is not a valid substitution target\n";
        }

        $v =~ s/\x{fffd}/,/g;

        $params->{ $k } = $v;

    }

    return $params;

}

sub _get_template {

    my ($self, $str, %param) = @_;
    my $no_path = $param{ no_path } // 0;

    my ($p) =
        grep { -e }
        map { File::Spec->catfile($_, "$str.stubb") }
        @{ $self->{ TempDir } };


    if ($str !~ /[\/\\]/ and defined $p) {
        return $p;
    } elsif (!$no_path and -e $str) {
        return $str;
    } else {
        return undef;
    }

}

sub render {

    my ($self) = @_;

    my $render = File::Stubb::Render->new(
        template        => $self->{ Template    },
        subst           => $self->{ Subst       },
        ignore_config   => $self->{ IgnoreConf  },
        render_hidden   => $self->{ Hidden      },
        follow_symlinks => $self->{ FollowLinks },
        copy_perms      => $self->{ CopyPerms   },
        defaults        => $self->{ Defaults    },
    );

    my @created;

    for my $f (@{ $self->{ Files } }) {
        push @created, $render->render($f);
    }

    if ($self->{ Verbose } and $self->{ Files }[0] ne '-') {
        say "Created:";
        for my $f (@created) {
            say "  $f";
        }
    }

    return 1;

}

sub list {

    my ($self) = @_;

    my $render = File::Stubb::Render->new(
        template        => $self->{ Template    },
        ignore_config   => $self->{ IgnoreConf  },
        hidden          => $self->{ Hidden      },
        follow_symlinks => $self->{ FollowLinks },
    );

    my $targets = $render->targets;

    my $have_basic = !! @{ $targets->{ basic } };
    my $have_perl  = !! @{ $targets->{ perl  } };
    my $have_shell = !! @{ $targets->{ shell } };

    unless ($have_basic or $have_perl or $have_shell) {
        say "No targets in $self->{ Template }";
        return 1;
    }

    if ($have_basic) {
        say "Substitution targets:";
        for my $t (@{ $targets->{ basic } }) {
            say "  $t";
        }
        print "\n" if $have_perl or $have_shell;
    }

    if ($have_perl) {
        say "Perl targets:";
        for my $t (@{ $targets->{ perl } }) {
            say "  $t";
        }
        print "\n" if $have_shell;
    }

    if ($have_shell) {
        say "Shell targets:";
        for my $t (@{ $targets->{ shell } }) {
            say "  $t";
        }
    }

    return 1;

}

sub init {

    my ($class) = @_;

    my $self = {
        Mode        => MODE_DEFAULT,
        Files       => [],
        Template    => undef,
        Subst       => undef,
        TempDir     => [],
        Verbose     => 1,
        # Render options
        Hidden      => undef,
        FollowLinks => undef,
        CopyPerms   => undef,
        Defaults    => undef,
        IgnoreConf  => undef,
    };

    bless $self, $class;

    my $subst = [];
    my $temp;

    Getopt::Long::config('bundling');
    GetOptions(
        'template-dir|d=s' => $self->{ TempDir },
        'template|t=s'     => sub {
            $self->{ Mode } = MODE_BATCH;
            $temp = $_[1];
        },
        'substitute|s=s'   => $subst,
        'list|l'           => sub { $self->{ Mode } = MODE_LIST },
        'quiet|q'          => sub { $self->{ Verbose } = 0 },
        # Render options
        'hidden|a'             => sub { $self->{ Hidden      } = 1 },
        'no-hidden|A'          => sub { $self->{ Hidden      } = 0 },
        'follow-symlinks|w'    => sub { $self->{ FollowLinks } = 1 },
        'no-follow-symlinks|W' => sub { $self->{ FollowLinks } = 0 },
        'copy-perms|c'         => sub { $self->{ CopyPerms   } = 1 },
        'no-copy-perms|C'      => sub { $self->{ CopyPerms   } = 0 },
        'no-defaults|U'        => sub { $self->{ Defaults    } = 0 },
        'no-config|I'          => sub { $self->{ IgnoreConf  } = 1 },
        # Message options
        'help|h'    => sub { print $HELP;    exit 0 },
        'version|v' => sub { print $VER_MSG; exit 0 },
    ) or die "Invalid command-line arguments\n";

    if (exists $ENV{ STUBB_TEMPLATES }) {
        push @{ $self->{ TempDir } }, split /:/, $ENV{ STUBB_TEMPLATES };
    }

    push @{ $self->{ TempDir } }, File::Spec->catfile(home, '.stubb');

    if ($self->{ Mode } == MODE_DEFAULT) {
        $self->{ Files }[0] = shift @ARGV // die $HELP;
        $temp = shift @ARGV;
        if (defined $temp) {
            $self->{ Template } = $self->_get_template($temp)
                // die "'$temp' is not a valid template\n";
        } else {
            $temp = (fileparse($self->{ Files }[0], qr/\.[^.]*/))[2];
            $temp =~ s/^\.//;
            if ($temp eq '') {
                die "Please specify a stub template either by an additional argument or a file suffix\n";
            }
            $self->{ Template } = $self->_get_template($temp, no_path => 1)
                // die "'$temp' is not a valid template\n";
        }
    } elsif ($self->{ Mode } == MODE_BATCH) {
        die $HELP unless @ARGV;
        $self->{ Template } = $self->_get_template($temp);
        $self->{ Files } = [ @ARGV ];
        if (@{ $self->{ Files } } > 1 and grep { $_ eq '-' } @{ $self->{ Files } }) {
            die "Cannot write stub to stdout in batch stub creation\n";
        }
    } elsif ($self->{ Mode } == MODE_LIST) {
        $temp = shift @ARGV // die $HELP;
        $self->{ Template } = $self->_get_template($temp)
            // die "'$temp' is not a valid template\n";
    }

    if (@$subst) {
        $self->{ Subst } = _subst_params(
            # Don't lead trailing backslashes escape commas in next param
            join ',', map { $_ =~ s/\\$/\\ /r } @$subst
        );
    }

    return $self;

}

sub run {

    my ($self) = @_;

    if ($self->{ Mode } == MODE_DEFAULT or $self->{ Mode } == MODE_BATCH) {
        $self->render;
    } elsif ($self->{ Mode } == MODE_LIST) {
        $self->list;
    }

    return 1;

}

1;

=head1 NAME

File::Stubb - Stub file creator

=head1 USAGE

  use File::Stubb;

  my $stubb = File::Stubb->init;
  $stubb->run;

=head1 DESCRIPTION

B<File::Stubb> is the module that provides the command-line interface for
L<stubb>. This is a private module, for user documentation you should consult
the L<stubb> manual.

=head1 METHODS

=over 4

=item $stubb = File::Stubb->init;

Reads C<@ARGV> and returns a blessed B<File::Stubb> object. View the L<stubb>
manual for a list of valid arguments.

=item $stubb->run;

Runs L<stubb> based on the arguments parsed during C<init()>.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/stubb.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<stubb>

=cut

# vim: expandtab shiftwidth=4
