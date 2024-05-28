
use Mojo::Util qw/dumper/;

{
    package Grid::Size;
    use Moo;
    use Mojo::Util qw/dumper/;

    use Carp;
    use overload
	'0+' => "uom_size",
	# '+' =>  "uom_sum",
	# '-' =>  "uom_diff",
	# '*' =>  "uom_mult",
	'""' => sub { return shift->size },
	fallback => 1;

    has "size"   => (is  => 'rw');
    has "grid"   => (is  => 'rw');
    has "int"    => (is  => 'rw', default => 0);

    sub uom_size {
	my $self = shift;
	my ($perc, $base, $dir) = ($self->size =~ /(\d+)([p,i])([w,h])/);

	$base = $base eq "p" ? "page" : "item";
	$dir  = $dir  eq "w" ? "width" : "height";

	my $method = join "_", $base, $dir;
	$base = $self->grid->$method;
	my $size = $perc * $base / 100;
	return 0 + ($self->int ? (sprintf "%.0f", $size) : $size);
    }

    sub uom_sum {
	my ($one, $two) = @_;
	return $one->uom_size + $two->uom_size
    }
    sub uom_diff {
	my ($one, $two) = @_;
	return $one->uom_size - $two->uom_size
    }
    sub uom_mult {
	my ($one, $two, $inv) = @_;
	return $one->uom_size * $two;
    }
}

{
    package Grid;
    use Moo;
    use Mojo::Util qw/dumper/;

    use Types::Standard qw( InstanceOf );

    has [qw/page_width page_height grid_width grid_height/] => (is => "rw");
    has [qw/border gutter item_width item_height/]
	=> (
	    is => "rw",
	    isa => InstanceOf["Grid::Size"],
	    coerce =>  sub { Grid::Size->new({ size => shift }) },
	   );

    around [qw/border gutter item_width item_height/] => sub {
	my $orig = shift;
	my $ret = $orig->(@_);
	$ret->grid($_[0]);
	return $ret;
    };


    around BUILDARGS => sub {
	my ( $orig, $class, $opts ) = @_;

	for (qw/border gutter item_width item_height/) {
	    $opts->{$_} = Grid::Size->new({ size => $opts->{$_} })
	}
	my $ret = $class->$orig($opts);
	return $ret;
    };
    # after "new" => sub {
    # 	print "new", dumper \@_;
    # 	# my $ret = shift;
    # 	# # print $ret;
    # 	# for (qw/border gutter item_width item_height/) {
    # 	#     print $ret->$_;
    # 	# }

    # }
};

$\ = "\n"; $, = "\t"; binmode(STDOUT, ":utf8");

my $g = Grid->new({ page_width => 297, page_height => 210, grid_width => 4, grid_height => 3, border => "1pw" });
print "border", $g->border, 0 + $g->border;
$g->border(16);
print "border", $g->border;

my $n = Grid::Size->new({ size => "8pw", grid => $g  });
my $t = Grid::Size->new({ size => "4pw", grid => $g  });

sub Grid::repage {
    my $self = shift;
    my $opts = shift;
}

print $n, $t, $n->uom_size, $t->uom_size, $n + $t;
print $n, $t, $n->uom_size, $t->uom_size, $n - $t;
print $n, $t, $n->uom_size, $t->uom_size, $t * 5;
print $n, $t, $n->uom_size, $t->uom_size, 5 * $t;
print $n, $t, $n->uom_size, $t->uom_size, $t / 2;
print $n, $t, $n->uom_size, $t->uom_size, 100 / $t;

__DATA__

page is set => everything is relative
items are set => page is calculated
