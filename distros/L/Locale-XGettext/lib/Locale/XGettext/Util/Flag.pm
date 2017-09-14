#! /bin/false

# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

package Locale::XGettext::Util::Flag;

use strict;

use Locale::TextDomain qw(Locale-XGettext);

sub new {
    my ($class, %args) = @_;

    return if !defined $args{function};
    return if !defined $args{flag};
    return if !defined $args{arg};
    return if !length $args{function};
    return if !length $args{flag};
    # That would break the output.
    return if $args{flag} =~ /\n/;
    return if $args{arg} !~ /^[1-9][0-9]*$/;

    if (!$args{pass} && !$args{arg}) {
        $args{pass} = 1 if $args{flag} =~ s/^pass-//;
        $args{no} = 1 if $args{flag} =~ s/^no-//;
    }

    my %seen;
    my $comment;
    my $comment_seen;
    my $context_seen;
    my $self = {
        function => $args{function},
        arg => $args{arg},
        flag => $args{flag}
    };

    $self->{pass} = 1 if $args{pass};
    $self->{no} = 1 if $args{no};

    bless $self, $class;
}

sub newFromString {
    my ($class, $orig_spec) = @_;
    
    my $spec = $orig_spec;
    $spec =~ s/\s+//g;

    my ($function, $arg, $flag) = split /:/, $spec, 3;
    
    my ($pass, $no);
    $pass = 1 if $flag =~ s/^pass-//;
    $no = 1 if $flag =~ s/^no-//;

    return $class->new(
        function => $function,
        arg => $arg,
        flag => $flag,
        no => $no,
        pass => $pass,
    );
}

sub function {
    shift->{function};
}

sub arg {
    shift->{arg};
}

sub flag {
    shift->{flag}
}

sub no {
    shift->{no};
}

sub pass {
    shift->{pass};
}

sub dump {
    my ($self) = @_;

    return join ':', 
           grep { defined }
           $self->function, $self->arg,
           $self->pass, $self->no, $self->flag; 
}

1;
