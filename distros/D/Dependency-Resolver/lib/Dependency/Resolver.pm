package Dependency::Resolver;
$Dependency::Resolver::VERSION = '0.07';
use utf8;
use Moose;

has modules => (
               is       => "rw",
               isa      => "HashRef",
               default  => sub { {} },
           );

has addr => (
               is       => "rw",
               isa      => "HashRef",
               default  => sub { {} },
           );

sub add {
    my ($self, @nodes) = @_;

    foreach my $n (@nodes){
        push(@{$self->modules->{$n->{name}}}, $n);
        $self->addr->{"$n"} = $n;
    }
    return 1;
}

sub dep_resolv {
    my ($self, $node, $resolved, $seen) = @_;

    $resolved ||= [];
    $seen     ||= [];

    push( @$seen, $node);
    for my $dep_version ( @{$node->{deps}} ) {

        my $dep = $self->search_best_dep($dep_version);

        # if dep is not in resolved
        if ( ! grep { $_ eq $dep} @$resolved ) {

            die sprintf "Circular reference detected: %s -> %s", $node->name, $dep->name
                if ( grep { $_ eq $dep} @$seen);

            $self->dep_resolv( $dep, $resolved, $seen );
        }
    }
    push( @$resolved, $node);
    return $resolved;
}


sub parse_module_args {
    my($self, $module) = @_;

    $module =~ s/\s+//g;
    $module =~ m/^([A-Za-z0-9_:]+)([\s!<>=]+)(.*)$/;
    my ($mod,$op,$ver) = ($1, $2, $3);
    if ( ! defined $op ) { $mod = $module, $op = '>=', $ver = 0};
    return ($mod,$op,$ver);
}

sub search_best_dep{
    my($self, $dep_args) = @_;

    # ex: dep_args : B >1, B<=3
    my $result = [];
    foreach my $dep ( split(/,/, $dep_args)){

        my($mod,$op,$ver) = $self->parse_module_args($dep);
        my $modules = $self->get_modules($mod, $op, $ver);

        my %count = ();
        $count{$_}++
            for (@$result, @$modules);

        my @intersection  = grep { $count{$_} == 2 } keys %count;

        if( $result->[0] ){
            $result = [ $self->_addr_to_mod(@intersection) ];
        }
        else{  $result = $modules}
    }

    $result = $self->_sort_by_version($result);
    die "Module $dep_args non found ! " if ( ! defined $result->[-1] );
    # returns the highest version
    return $result->[-1];
}


sub _sort_by_version {
    my ( $self, $nodes ) = @_;

    return [ sort { $a->{version} cmp $b->{version} }  @$nodes ];
}

sub _addr_to_mod {
    my ( $self,@addrs ) = @_;

    return map {  $self->addr->{$_} } @addrs;
}


sub get_modules{
    my $self = shift;
    my $mod  = shift;
    my $op   = shift || '>=';
    my $ver  = shift || 0;
    $op = '==' if $op eq '=';


    die "Operator '$op' is unknown"
        if (! grep { $op eq $_ } qw(== != < > >= <= ));

    my $modules = [];
    foreach my $m (@{$self->modules->{$mod}}){
        my $mver = $m->{version};
        if ( eval "$mver $op $ver"  ){
            push(@$modules, $m);
        }
    }
    return $self->_sort_by_version($modules);
}


=head1 NAME

Dependency::Resolver - Simple Dependency resolving algorithm

=head1 VERSION

version 0.07

based on http://www.electricmonk.nl/log/2008/08/07/dependency-resolving-algorithm/

=head1 SYNOPSIS

build dependencies tree

    my $a  = { name => 'A' , version => 1, deps => [ 'B == 1', 'D']};
    my $a2 = { name => 'A' , version => 2, deps => [ 'B => 2, B < 3', 'D']};
    my $b1 = { name => 'B' , version => 1, deps => [ 'C == 1',  'E'] };
    my $b2 = { name => 'B' , version => 2, deps => [ 'C == 2',  'E'] };
    my $b3 = { name => 'B' , version => 3, deps => [ 'C == 3',  'E'] };
    my $c1 = { name => 'C' , version => 1, deps => [ 'D', 'E'] };
    my $c2 = { name => 'C' , version => 2, deps => [ 'D', 'E'] };
    my $c3 = { name => 'C' , version => 3, deps => [ 'D', 'E'] };
    my $d  = { name => 'D' , version => 1};
    my $e  = { name => 'E' , version => 1};

    my $resolver = Dependency::Resolver->new;

    my $resolved = $resolver->dep_resolv($a);
    #  return [ $d, $e, $c1, $b1, $a ]

    $resolved = $resolver->dep_resolv($a2);
    # return [ $d, $e, $c2, $b2, $a2 ]

    # method used by dep_resolv (get_module, search_best_dep)
    $resolver->get_modules('B', '==', 1); # return  [$b1]
    $resolver->get_modules('B', '<=', 2); # return  [$b1, $b2]
    $resolver->get_modules('B', '>=', 1); # return  [$b1, $b2, $b3]

    $resolver->search_best_dep('B >= 1');       # return $b3 (highest version)
    $resolver->search_best_dep('B >= 1, B!=3');       # return $b2
    $resolver->search_best_dep('B >= 1, B<=3, B!=3'); # return $b2


=head1 SUBROUTINES/METHODS

=head2 dep_resolv($node)

returns an arrayref of nodes resolved

=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dependency-resolver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dependency-Resolver>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dependency::Resolver


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dependency-Resolver>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dependency-Resolver>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dependency-Resolver>

=item * Search CPAN

L<http://search.cpan.org/dist/Dependency-Resolver/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Daniel Brosseau.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Dependency::Resolver
