# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2002,2003,2005,2008,2013,2020 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://www.rezic.de/eserte/
#

package GraphViz::Makefile;
use GraphViz;
use Make;
use strict;

use vars qw($VERSION $V);
$VERSION = '1.18';

$V = 0 unless defined $V;

sub new {
    my($pkg, $g, $make, $prefix, %args) = @_;
    $g = GraphViz->new unless $g;
    if (!$make) {
	$make = Make->new;
    } elsif (!UNIVERSAL::isa($make, "Make")) {
	my $makefile = $make;
	$make = Make->new;
	$make->parse($makefile);
    }

    my @allowed_args = qw(reversed);
    my %allowed_args = map {($_,undef)} @allowed_args;
    while(my($k,$v) = each %args) {
	die "Unrecognized argument $k, known arguments are @allowed_args"
	    if !exists $allowed_args{$k};
    }

    my $self = { GraphViz => $g,
		 Make     => $make,
		 Prefix   => ($prefix||""),
		 %args
	       };
    bless $self, $pkg;
}

sub GraphViz { shift->{GraphViz} }
sub Make     { shift->{Make}     }

sub generate {
    my($self, $target) = @_;
    $target = "all" if !defined $target;
    $self->_generate($self->{Make}->expand($target), {});
}

sub _generate {
    my($self, $target, $seen) = @_;
    return if $seen->{$target};
    $seen->{$target}++;
    if (!$self->{Make}->has_target($target)) {
	warn "Can't get make target for $target\n" if $V;
	return;
    }
    my $make_target = $self->{Make}->target($target);
    my @depends = $self->_all_depends($make_target);
    if (!@depends) {
	warn "No depends for target $target\n" if $V;
	return;
    }
    my $g = $self->{GraphViz};
    my $prefix = $self->{Prefix};
    $g->add_node($prefix.$target);
    foreach my $dep (@depends) {
	$g->add_node($prefix.$dep) unless $seen->{$dep};
	if ($self->{reversed}) {
	    $g->add_edge($prefix.$dep, $prefix.$target);
	    warn "$prefix$dep => $prefix$target\n" if $V >= 2;
	} else {
	    $g->add_edge($prefix.$target, $prefix.$dep);
	    warn "$prefix$target => $prefix$dep\n" if $V >= 2;
	}
    }
    $self->_generate($_, $seen) for @depends;
}

sub guess_external_makes {
    my($self, $target_name, $cmd) = @_;
    if (defined $cmd && $cmd =~ /\bcd\s+(\w+)\s*(?:;|&&)\s*make\s*(.*)/) {
	my($dir, $makeargs) = ($1, $2);
	my $makefile;
	my $rule;
	{
	    require Getopt::Long;
	    local @ARGV = split /\s+/, $makeargs;
	    $makefile = "makefile";
	    # XXX parse more options
	    Getopt::Long::GetOptions("f=s" => \$makefile);
	    my @env;
	    foreach (@ARGV) {
		if (!defined $rule) {
		    $rule = $_;
		} elsif (/=/) {
		    push @env, $_;
		}
	    }
	}

#	warn "dir: $dir, file: $makefile, rule: $rule\n";
	my $f = "$dir/$makefile"; # XXX make better. use $make->{GNU}
	$f = "$dir/Makefile" if !-r $f;
	my $gm2 = GraphViz::Makefile->new($self->{GraphViz}, $f, "$dir/"); # XXX save_pwd verwenden; -f option auswerten
	$gm2->generate($rule);

	$self->{GraphViz}->add_edge($target_name, "$dir/$rule");
    } else {
	warn "can't match external make command in $cmd\n" if $V;
    }
}

sub _all_depends {
    my($self, $make_target) = @_;
    my @rules = @{ $make_target->rules };
    $self->guess_external_makes($make_target->Name, $_)
	for map @{ $_->exp_recipe($make_target) }, @rules;
    map @{ $_->prereqs }, @rules;
}

1;


__END__

=head1 NAME

GraphViz::Makefile - Create Makefile graphs using GraphViz

=head1 SYNOPSIS

Output to a .png file:

    use GraphViz::Makefile;
    my $gm = GraphViz::Makefile->new(undef, "Makefile");
    $gm->generate("all"); # or another makefile target
    open my $ofh, ">", "makefile.png" or die $!;
    binmode $ofh;
    print $ofh $gm->GraphViz->as_png;

Output to a .ps file:

    use GraphViz::Makefile;
    my $gm = GraphViz::Makefile->new(undef, "Makefile");
    $gm->generate("all"); # or another makefile target
    open my $ofh, ">", "makefile.ps" or die $!;
    binmode $ofh;
    print $ofh $gm->GraphViz->as_ps;

=head1 DESCRIPTION

B<GraphViz::Makefile> uses the L<GraphViz> and L<Make> modules to
visualize Makefile dependencies.

=head2 METHODS

=over

=item new($graphviz, $makefile, $prefix, %args)

Create a C<GraphViz::Makefile> object. The first argument should be a
C<GraphViz> object or C<undef>. In the latter case, a new C<GraphViz>
object is created by the constructor. The second argument should be a
C<Make> object, the filename of a Makefile, or C<undef>. In the latter
case, the default Makefile is used. The third argument C<$prefix> is
optional and can be used to prepend a prefix to all rule names in the
graph output.

Further arguments (specified as key-value pairs):

=over

=item reversed => 1

Point arrows in the direction of dependencies. If not set, then the
arrows point in the direction of "build flow".

=back

=item generate($rule)

Generate the graph, beginning at the named Makefile rule. If C<$rule>
is not given, C<all> is used instead.

=item GraphViz

Return a reference to the C<GraphViz> object. This object can be used
for the output methods.

=item Make

Return a reference to the C<Make> object.
 
=back

=head2 MEMBERS

For backward compatibility, the following members in the hash-based
C<GraphViz::Makefile> object may be used instead of the methods:

=over

=item * GraphViz

=item * Make

=back

=head2 ALTERNATIVES

There's another module doing the same thing: L<Makefile::GraphViz>.

=head1 AUTHOR

Slaven Rezic <srezic@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002,2003,2005,2008,2013 Slaven Rezic. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<GraphViz>, L<Make>, L<make(1)>, L<tkgvizmakefile>.

=cut
