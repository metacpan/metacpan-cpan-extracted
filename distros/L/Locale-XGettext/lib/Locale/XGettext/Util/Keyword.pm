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

package Locale::XGettext::Util::Keyword;

use strict;

use Locale::TextDomain qw(Locale-XGettext);

sub new {
    my ($class, $function, @args) = @_;
    
    my %seen;
    my $comment;
    my $comment_seen;
    my $context_seen;
    my $self = {
        function => $function,
        singular => 0,
        plural => 0,
        context => 0,
    };
        
    foreach my $arg (@args) {
        $arg = 1 if !defined $arg;
        $arg = 1 if !length $arg;
        if ($arg =~ /^([1-9][0-9]*)(c?)$/) {
            my ($pos, $is_ctx) = ($1, $2);
            die __x("Multiple meanings for argument #{num} for function '{function}'!\n",
                     function => $function, num => $pos)
                if ($seen{$pos}++);
            if ($is_ctx) {
                die __x("Multiple context arguments for function '{function}'!\n",
                         function => $function) 
                    if $context_seen++;
                $self->{context} = $pos;
            } elsif ($self->{plural}) {
                die __x("Too many forms for '{function}'!\n",
                        function => $function); 
            } elsif ($self->{singular}) {
                $self->{plural} = $pos;
            } else {
                $self->{singular} = $pos;
            }
        } elsif ($arg =~ /^"(.*)"$/) {
              die __x("Multiple automatic comments for function '{function}'!\n",
                      function => $function)
                  if $comment_seen++;
              $self->{comment} = $1;
        } else {
              die __x("Invalid argument specification '{spec}' for function '{function}'!\n",
                      function => $function, spec => $arg);
        }
    }

    $self->{singular} ||= 1;

    bless $self, $class;
}

sub newFromString {
    my ($class, $spec) = @_;
    
    # Strip off a possible automatic comment.
    my @tokens;
    my $comment_seen;
    my $forms_seen = 0;
    my $context_seen;
    while (@tokens < 4 && length $spec) {
        if ($spec =~ s/([,:])[\s]*([1-9][0-9]*c?)[\s]*$//) {
            my ($sep, $token) = ($1, $2);
            if ($token =~ /c$/) {
                if ($context_seen) {
                    $spec .= ":$token";
                    last;
                }
                $context_seen = 1;
            } else {
                if ($forms_seen >= 2) {
                    $spec .= ":$token";
                    last;
                }
                ++$forms_seen;
            }
            unshift @tokens, $token;

            last if ':' eq $sep;
        } elsif ($spec =~ s/([,:])[\s]*"(.*)"[\s]*$//) {
            my ($sep, $token) = ($1, $2);
            if ($comment_seen) {
                $spec .= qq{:"$token"};
                last;
            }

            my $comment = $token;
            # This is what GNU xgettxt does.
            $comment =~ s/"//;
            unshift @tokens, qq{"$token"};
            
            last if ':' eq $sep;
        } else {
            last;
        }
    }
    my $function = $spec;
    $function = shift @tokens if !length $spec;

    return $class->new($function, @tokens);
}

sub function {
    shift->{function};
}

sub singular {
    shift->{singular};
}

sub plural {
    shift->{plural}
}

sub context {
    shift->{context};
}

sub comment {
    shift->{comment};
}

sub dump {
    my ($self) = @_;

    my $dump = $self->function . ':';
    $dump .= $self->context . 'c,' if $self->context;
    $dump .= $self->singular . ',';
    $dump .= $self->plural . '.' if $self->plural;
    chop $dump;

    return $dump;
}

1;
