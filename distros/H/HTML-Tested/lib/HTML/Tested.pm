=head1 NAME

HTML::Tested - Provides HTML widgets with the built-in means of testing.

=head1 SYNOPSIS

    package MyPage;
    use base 'HTML::Tested';

    __PACKAGE__->make_tested_value('x');

    # Register my own widget
    __PACKAGE__->register_tested_widget('my_widget', 'My::App::Widget');
    __PACKAGE__->make_tested_my_widget('w');


    # Later, in the test for example
    package main;

    my $p = MyPage->construct_somehow;
    $p->x('Hi');
    my $stash = {};

    $p->ht_render($stash);

    # stash contains x => 'Hi'
    # We can pass it to templating mechanism

    # Stash checking function
    my @errors = HTML::Tested::Test->check_stash(
            'MyPage', $stash, { x => 'Hi' });

    # Stash checking function
    my @errors = HTML::Tested::Test->check_text(
            'MyPage', '<html>x</html>', { x => 'Hi' });

=head1 DISCLAIMER
	
This is pre-alpha quality software. Please use it on your own risk.

=head1 INTRODUCTION

Imagine common web programming scenario - you have HTML page packed with
checkboxes, edit boxes, labels etc.

You are probably using some kind of templating mechanism for this page already.
However, your generating routine still has quite a lot of complex code.

Now, being an experienced XP programmer, you face the task of writing test
code for the routine. Note, that your test code can deal with the results on
two levels: we can check the stash that we are going to pass to the templating module
or we can crawl our site and check the resulting text.

As you can imagine both of those scenarios require quite a lot of effort to
get right.

HTML::Tested can help here. It does this by generating stash data from the
widgets that you declare. Its testing code can check the existence of those
widgets both in the stash and in the text of the page.

=cut

use strict;
use warnings FATAL => 'all';

package HTML::Tested;
use base 'Exporter', 'Class::Accessor', 'Class::Data::Inheritable';
use Carp;
our $VERSION = '0.58';

our @EXPORT_OK = qw(HT HTV);

use constant HT => 'HTML::Tested';
use constant HTV => 'HTML::Tested::Value';

__PACKAGE__->mk_classdata('Widgets_List', []);
__PACKAGE__->mk_classdata('_Widgets_Hash', {});

=head1 METHODS

=head2 $class->ht_add_widget($widget_class, $widget_name, @widget_args)

Adds widget implemented by C<$widget_class> to C<$class> as C<$widget_name>.
C<@widget_args> are passed as is into $widget_class->new function.

For example, A->ht_add_widget("HTML::Tested::Value", "a", default_value => "b");
will create value widget (and corresponding C<a> accessor) in A class which
will have default value "b".

See widget C<new> function documentation for relevant C<@widget_args> values
(most of them are documented in L<HTML::Tested::Value> class).

=cut
sub ht_add_widget {
	my ($class, $widget_class, $name, @args) = @_;
	confess sprintf('Widget "%s" already exists', $name)
		if $class->ht_find_widget($name);
	$class->mk_accessors($name);
	my $res = $widget_class->new($class, $name, @args);

	# to avoid inheritance troubles...
	my @wl = @{ $class->Widgets_List || [] };
	push @wl, $res;
	$class->Widgets_List(\@wl);

	my %wh = %{ $class->_Widgets_Hash || {} };
	$wh{ $res->name } = $res;
	$class->_Widgets_Hash(\%wh);
	$res->compile($class) if $res->can('compile');
	return $res;
}

sub _ht_render_i {
	my ($self, $stash, $parent_name) = @_;
	for my $v (@{ $self->Widgets_List }) {
		my $n = $v->name;
		my $id = $parent_name ? $parent_name . "__$n" : $n;
		$v->render($self, $stash, $id, $n);
	}
}

=head2 ht_render(stash)

Renders all of the contained controls into the stash.
C<stash> should be hash reference.

=cut
sub ht_render { shift()->_ht_render_i(shift); }

=head2 ht_find_widget($widget_name)

Finds widget named C<$widget_name>.

=cut
sub ht_find_widget {
	my ($self, $wn) = @_;
	return $self->_Widgets_Hash->{$wn};
}

=head2 ht_bless_from_tree(class, tree)

Creates blessed instance of the class from tree.

=cut
sub ht_bless_from_tree {
	my ($class, $tree) = @_;
	my $res = {};
	while (my ($n, $v) = each %$tree) {
		my $wc = $class->ht_find_widget($n);
		$res->{$n} = $wc ? $wc->bless_from_tree($v) : $v;
	}
	return bless($res, $class);
}

sub _ht_set_one {
	my ($self, $func, $val, @path) = @_;
	my $p = shift(@path) or return;
	my $wc = $self->ht_find_widget($p) or return;
	$wc->$func($self, $val, @path);
}

sub _call_finish_load {
	my $self = shift;
	my $wl = $self->Widgets_List;
	$_->finish_load($self) for grep { $_->can('finish_load') } @$wl;
}

sub _for_each_arg_set_one {
	my ($self, $func, %args) = @_;
	$self->_ht_set_one($func, $args{$_}, split('__', $_)) for keys %args;
	$self->_call_finish_load;
}

sub ht_load_from_params {
	my ($class, %args) = @_;
	my $self = $class->new;
	$self->_for_each_arg_set_one("absorb_one_value", %args);
	return $self;
}

=head2 ht_get_widget_option($widget_name, $option_name)

Gets option C<$option_name> for widget named C<$widget_name>.

=cut
sub ht_get_widget_option {
	my ($self, $wn, $opname) = @_;
	my $w = $self->ht_find_widget($wn) or confess "Unknown widget $wn";
	return $w->_get_option($self, $wn, $opname);
}

=head2 ht_set_widget_option($widget_name, $option_name, $value)

Sets option C<$option_name> to C<$value> for widget named C<$widget_name>.

=cut
sub ht_set_widget_option {
	my ($self, $wname, $opname, $val) = @_;
	my $w = $self->ht_find_widget($wname)
		or confess "Unknown widget $wname";
	if (ref($self)) {
		$self->{"__ht__$wname\_$opname"} = $val;
	} else {
		$w->options->{$opname} = $val;
	}
	$w->compile($self);
}

=head2 $root->ht_validate

Recursively validates all contained widgets. See C<HTML::Tested::Value> for
C<$widget->validate> method description.

Prepends the names of the widgets which failed validation into result arrays.

=cut
sub ht_validate {
	my $self = shift;
	return map { $_->validate($self) } @{ $self->Widgets_List };
}

=head2 $root->ht_make_query_string($uri, @widget_names)

Makes query string from $uri and widget values.

=cut
sub ht_make_query_string {
	my ($self, $uri, @widget_names) = @_;
	return $uri unless @widget_names;
	$uri .= ($uri =~ /\?/) ? "&" : "?";
	return $uri . join("&", map {
		"$_=" . $self->ht_find_widget($_)->prepare_value($self, $_, $_)
	} @widget_names);
}

=head2 $root->ht_merge_params(@params)

Merges parameters with current values. Tries to reconstruct the state of the
controls to user set values.

E.g. for EditBox it means setting its value to one in params. For checkbox -
setting its C<checked> state.

=cut
sub ht_merge_params {
	my ($self, %params) = @_;
	$self->_for_each_arg_set_one("merge_one_value", %params);
}

sub ht_encode_errors {
	my ($class, @errs) = @_;
	return join(",", map { $_->[0] . ":" . $_->[1] } @errs);
}

sub _error_one {
	my ($self, $stash, $var_name, $n, $v) = @_;
	my @ns = split('__', $n);
	while (@ns > 1) {
		my $ln = shift @ns;
		my $lidx = shift @ns;

		$stash = $stash->{$ln}->[ $lidx - 1 ];
	}
	$stash->{$var_name}->{ $ns[0] } = $v;
}

sub ht_error_render {
	my ($self, $stash, $var_name, $err) = @_;
	$self->_error_one($stash, $var_name, split(':')) for split(',', $err);
}

1;

=head1 BUGS

Documentation is too sparse to be taken seriously.

=head1 AUTHOR

	Boris Sukholitko
	CPAN ID: BOSU
	
	boriss@gmail.com
	

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

HTML::Tested::Test for writing tests using HTML::Tested.
See HTML::Tested::Value::* for the documentation on the specific
widgets.
See HTML::Tested::List for documentation on list container.

=cut

