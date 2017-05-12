# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::TT::Translate;
use strict;
use warnings;

# WARNING: Template-Toolkit seems to have a special problem with Perl::Critic,
# disable this one check for this file
## no critic (BuiltinHomonyms)

use Data::Dumper;
use Maplat::Helpers::Translator;

our $VERSION = 0.995;

use Carp;

use base qw(Template::Plugin);

use Template::Plugin;
use Template::Exception;

sub load {
    my ($class, $context) = @_;
    my $self = bless {
        dbh => getDBH(),
        memh => getMEMH(),
    }, $class;

    return $self;
}

sub new {
    my ($self, $context) = @_;
    return $self;
}

sub tr {
    my ($self, $data) = @_;
    my ($printer, $context) = @$self{ qw( _PRINTER _CONTEXT) };
    
    my $dbh = $self->getDBH;
    my $memh = $self->getMEMH;
    my $lang = $self->getLang;

    my $trans = tr_translate($dbh, $memh, $lang, $data);

    return $trans;
}

BEGIN {
    my $x_dbh;
    my $x_memh;
    my $x_lang;

    sub setDBH {
        my (undef, $newdbh) = @_;
        $x_dbh = $newdbh;
        return;
    }

    sub getDBH {
        return $x_dbh;
    }

    sub setMEMH {
        my (undef, $newmemh) = @_;
        $x_memh = $newmemh;
        return;
    }

    sub getMEMH {
        return $x_memh;
    }

    sub setLang {
        my (undef, $newlang) = @_;
        $x_lang = $newlang;
        return;
    }

    sub getLang {
        return $x_lang;
    }
}


1;
__END__

=head1 NAME

Maplat::Web::TT::Translate - Template-Toolkit Plugin for multilanguage support

=head1 SYNOPSIS

This is the Template-Toolkit plugin for multilanguage support

=head1 DESCRIPTION

This is an internal module.

=head2 getDBH

Internal function

=head2 getLang

Internal function

=head2 getMEMH

Internal function

=head2 setDBH

Internal function

=head2 setLang

Internal function

=head2 setMEMH

Internal function

=head2 tr

Internal function

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
