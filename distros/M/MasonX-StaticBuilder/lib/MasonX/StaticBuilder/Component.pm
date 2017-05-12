package MasonX::StaticBuilder::Component;

use strict;
use warnings;

use base qw(Class::Accessor);
MasonX::StaticBuilder::Component->mk_accessors(qw(comp_root comp_name));

use Carp;
use File::Spec;
use HTML::Mason;

=head1 NAME

MasonX::StaticBuilder::Component -- fill in a single template file

=head1 SYNOPSIS

    my $tmpl = MasonX::StaticBuilder::Component->new($file);
    my $output = $tmpl->fill_in(%args);
    print $output;

=head1 DESCRIPTION

=head2 new()

Constructor.  Give it a hashref containing the following args:

=over 4

=item *

comp_root

=item *

comp_name

=back

=begin testing

use_ok('MasonX::StaticBuilder::Component');
my $t = MasonX::StaticBuilder::Component->new({
    comp_root => "t",
    comp_name => "/test-component"
});
isa_ok($t, 'MasonX::StaticBuilder::Component');

can_ok($t, qw(comp_root comp_name));
like($t->comp_root(), qr!/t$!, "comp_root()");
is($t->comp_name(), "/test-component", "comp_name()");

my $no = MasonX::StaticBuilder::Component->new({
    comp_root => "t",
    comp_name => "/this/file/does/not/exist",
});
is($no, undef, "new returns undef if the file can't be loaded");

=end testing

=cut

sub new {
    my ($class, $args) = @_;

    my $comp_root = File::Spec->rel2abs($args->{comp_root});
    my $comp_name = $args->{comp_name};
    my $filename = $comp_root . $comp_name;

    if ($filename && -e $filename && -T $filename) {
        my $self = {};
        bless $self, $class;
        $self->comp_root($comp_root);
        $self->comp_name($comp_name);
        return $self;
    } else {
        return undef;
    }
}

=head2 fill_in()

Fill in the template, by running all the mason code in the template
files.  Any parameters passed to this method will be available to the
template as named args.

For example:

    $tmpl->fill_in( foo => "bar");

And in the template:

    <%args>
    $foo => undef
    </%args>

    Foo is <% $foo %>

=begin testing

my $t = MasonX::StaticBuilder::Component->new({
    comp_root => "t",
    comp_name => "/test-component"
});
my $out = $t->fill_in( foo => "bar" );
like($out, qr/This is a test/, "template handles simple text");
like($out, qr/42/, "template handles mason directives");
like($out, qr/foo is bar/, "template handles args");

=end testing

=cut

sub fill_in {
    my ($self, @args) = @_;
    my $output;
    my $interp = HTML::Mason::Interp->new( 
        comp_root => $self->comp_root(),
        out_method => \$output
    );
    $interp->exec($self->comp_name(), @args);
    return $output;
}

1;
