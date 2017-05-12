package Dist::Maker::Template;
use Mouse::Role;

requires qw(distribution);

sub moniker {
    my($self) = @_;
    my($moniker) = (ref($self) =~ / Template:: (.+) /xms);
    $moniker =~ s{::}{-}g;
    return $moniker;
}

sub mtime {
    my $module = ref($_[0]) . ".pm";
    $module =~ s{::}{/}g;
    return +( stat $INC{$module} )[9];
}

no Mouse::Role;
1;
__END__

=head1 NAME

Dist::Maker::Template - The role of distribution templates

=cut
