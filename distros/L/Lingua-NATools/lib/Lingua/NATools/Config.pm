# NATools - Package with parallel corpora tools
# Copyright (C) 2002-2012  Alberto Simões
#
# This package is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

package Lingua::NATools::Config;
our $VERSION = '0.7.10';
use 5.006;
use strict;
use warnings;

=head1 NAME

Lingua::NATools::Config - Simple configuration file API

=head1 SYNOPSIS

  use NAT::Config;

  my $config = Lingua::NATools::Config->new("config.cnf");
  my $val = $config->param("key");
  $config->param("key", ++$val);
  $config->write;

=head1 DESCRIPTION

=head2 C<new>

The NAT::Config object constructor receives the name of the file to be
processed. It returns an NAT::Config object ready to be queried.

    my $cnf = Lingua::NATools::Config("/path/to/the/configuration/file")->new;

You can also create a configuration object from scratch:

    my $cnf = Lingua::NATools::Config->new;

=cut

sub new {
    my $class = shift;
    my $self = {};
    local $/ = "\n";

    if ($_[0]) {
        my $file = shift;
        $self->{' filename '} = $file;

        open I, "$file" or die "Can't open file '$file'\n";
        while(<I>) {
            chomp;
            next if m!^\s*$!;
            next if m!^\s*#!;
            next if m!^\[!;
            my ($l,$r) = m!^([^=]+?)\s*=\s*(.*?)\s*$!;
            $self->{$l} = $r;
        }
        close I;
    }

    return bless $self => $class # amen
}

=head2 C<param>

This is the accessor method for any configuration parameter. Pass it
just one argument and you'll get that parameter value. Pass a second
argument and you are setting the parameter value.

   # get value for key "foo"
   $val = $cnf->param("foo");

   # set value "bar" for key "foo"
   $cnf->param("foo", "bar");

=cut

sub param {
    my $self  = shift;
    my $param = shift;

    my $val;
    if (defined($_[0])) {
        $val = shift;
        $self->{$param} = $val;
    } else {
        $val = exists($self->{$param})?$self->{$param}:undef;
    }
    return $val;
}

=head2 C<write>

This is the method used to write down the configuration object to a
file. If you have opened a configuration file with C<new>, then you
can just "save it":

   $cnf->write;

If you created a configuration object from scratch, you need to supply
a filename:

   $cnf->write("file.cnf");

You can always force a filename.

=cut

sub write {
    my $self     = shift;
    my $filename = shift;
    $filename = $self->{' filename '} if !$filename && exists $self->{' filename '};

    die "No filename supplied\n" unless $filename;

    open O, ">", $filename or die "Can't open file '$filename' for writing\n";
    print O "[nat]\n";
    for (keys %$self) {
        print O "$_=$self->{$_}\n";
    }
    close O;
}

1;
__END__

=head1 AUTHOR

Alberto Manuel Brandao Simoes, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2012 by Natura Project
http://natura.di.uminho.pt

This library is free software; you can redistribute it and/or modify
it under the GNU General Public License 2, which you should find on
parent directory. Distribution of this module should be done including
all NATools package, with respective copyright notice.

=cut
