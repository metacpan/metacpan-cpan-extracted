use strict;
use warnings FATAL => 'all';

package HTML::Tested::List;
use HTML::Tested::List::Renderer;
use HTML::Tested::List::Table;
use Carp;

sub new {
	my ($class, $parent, $name, $c, %args) = @_;
	$args{name} ||= $name;

	my @renderers = ('HTML::Tested::List::Renderer');
	push @renderers, HTML::Tested::List::Table->new if $args{render_table};

	$args{renderers} ||= \@renderers;
	{
		no strict 'refs';
		if (!$c) {
			$c = "$parent\::Item$name";
			push @{ "$c\::ISA" }, ($args{cbase} || "HTML::Tested");
		}
		*{ "$parent\::$name\_containee" } = sub { return $c; };
		*{ "$parent\::$name\_containee_do" } = sub {
			my ($self, $func, @args) = @_;
			return $self->$name($c->$func(@args));
		};
	};
	
	$args{containee} ||= $c;
	my $self = bless(\%args, $class);
	for my $r (@{ $self->renderers }) {
		$r->init($self, $parent);
	}
	return $self;
}

sub name { return shift()->{name}; }
sub renderers { return shift()->{renderers}; }
sub options { return {}; }
sub _get_option { return undef; }

sub render {
	my ($self, $caller, $stash, $id) = @_;
	for my $r (@{ $self->renderers }) {
		$r->render($self, $caller, $stash, $id);
	}
}

sub containee {
	my $res = shift()->{containee} or confess "No containee argument given";
	return $res;
}

sub bless_from_tree {
	my ($self, $p) = @_;
	my $target = $self->containee;
	return [ map { $target->ht_bless_from_tree($_) } @$p ];
}

sub merge_one_value { shift()->_do_one_value("merge_one_value", @_); }
sub absorb_one_value { shift()->_do_one_value("absorb_one_value", @_); }

sub _do_one_value {
	my ($self, $func, $root, $val, @path) = @_;
	my $arr = $root->{ $self->name } || [];
	my $id = shift(@path) or return;
	$arr->[--$id] ||= bless({}, $self->containee);
	$arr->[$id]->_ht_set_one($func, $val, @path);
	$root->{ $self->name } = $arr;
}

sub finish_load {
	my ($self, $root) = @_;
	my @arr = grep { $_ } @{ $root->{ $self->name } };
	$root->{ $self->name } = \@arr unless $self->{keep_holes};
	$_->_call_finish_load for @arr;
}

sub validate {
	my ($self, $caller) = @_;
	my $n = $self->name;
	my $arr = $caller->$n || [];
	my @res;
	for (my $i = 0; $i < @$arr; $i++) {
		push @res, map { [
			sprintf('%s__%d__%s', $n, $i + 1, shift @$_), @$_
		] } $arr->[$i]->ht_validate;
	}
	return @res;
}

1;

