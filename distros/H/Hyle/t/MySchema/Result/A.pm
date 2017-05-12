package MySchema::Result::A;

use base qw/DBIx::Class::Core/;
__PACKAGE__->table('A');
__PACKAGE__->add_columns(qw/a/);
__PACKAGE__->set_primary_key('a');

my %attr;
sub MODIFY_CODE_ATTRIBUTES {
    my ($pkg,$subref,@attr) = @_;
    $attr{$subref} =  \@attr;
    return;
}

sub FETCH_CODE_ATTRIBUTES {
    my ($pkg,$subref) = @_;
    my $attributes =$attr{$subref} or return;
    return wantarray ? @$attributes : $attributes;
}

sub foo :JSONP {
    my $self = shift;
    my %args = @_;

    return 1;
}
 
1;
