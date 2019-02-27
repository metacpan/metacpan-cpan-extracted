package MikroTik::Client::Query;
use MikroTik::Client::Mo;

use Exporter 'import';
use Scalar::Util 'blessed';

our @EXPORT_OK = ('build_query');


sub build_query {
    my $query = blessed $_[0] ? $_[1] : $_[0];

    return $$query if ref $query eq 'REF' && ref $$query eq 'ARRAY';

    if (my $type = ref $query) {
        return [_block(_ref_op($type), $query)];
    }
    else { return [] }
}

sub _block {
    my ($logic, $items) = @_;

    @{($items = [])} = map { $_ => $items->{$_} } sort keys %$items
        if ref $items eq 'HASH';
    my ($count, @words) = (0, ());

    while (my $el = shift @$items) {

        my @expr;
        if (ref $el eq 'REF' && ref $$el eq 'ARRAY') {
            @expr = @{$$el};

        }
        elsif (my $type = ref $el) {
            @expr = _block(_ref_op($type), $el);

        }
        elsif ($el =~ /^-(?:and|or)$/) {
            @expr = _block(_ref_op($el), shift @$items);

        }
        elsif ($el =~ /^-has(?:_not)?$/) {
            push @words, '?' . ($el eq '-has_not' ? '-' : '') . (shift @$items);
            $count++;
            next;

        }
        else {
            @expr = _value($el, shift @$items);
        }

        ++$count && push @words, @expr if @expr;
    }

    push @words, '?#' . ($logic x ($count - 1)) if $count > 1;
    return @words;
}

sub _ref_op {
    return
          ($_[0] eq 'HASH'  || $_[0] eq '-and') ? '&'
        : ($_[0] eq 'ARRAY' || $_[0] eq '-or')  ? '|'
        :                                         '';
}

sub _value {
    my ($name, $val) = @_;

    my $type = ref $val;
    if ($type eq 'HASH') {
        return _value_hash($name, $val);

    }
    elsif ($type eq 'ARRAY') {
        return _value_array($name, '=', $val);
    }

    # SCALAR
    return "?$name=" . ($val // '');
}

sub _value_array {
    my ($name, $op, $block) = @_;

    return () unless @$block;

    my $logic = '|';
    $logic = _ref_op(shift @$block)
        if @$block[0] eq '-and' || @$block[0] eq '-or';

    my ($count, @words) = (0, ());
    for (@$block) {
        my @expr
            = ref $_ eq 'HASH'
            ? _value_hash($name, $_)
            : _value_scalar($name, $op, $_);

        ++$count && push @words, @expr if @expr;
    }

    push @words, '?#' . ($logic x ($count - 1)) if $count > 1;
    return @words;
}

sub _value_hash {
    my ($name, $block) = @_;

    my @words = ();

    for my $op (sort keys %$block) {
        my $val = $block->{$op};
        return _value_array($name, $op, $val) if ref $val eq 'ARRAY';
        push @words, _value_scalar($name, $op, $val);
    }

    my $count = keys %$block;
    push @words, '?#' . ('&' x ($count - 1)) if $count > 1;
    return @words;
}

sub _value_scalar {
    my ($name, $op, $val) = (shift, shift, shift // '');

    return ("?$name=$val", '?#!') if $op eq '-not';
    return '?' . $name . $op . $val;
}

1;


=encoding utf8

=head1 NAME

MikroTik::Client::Query - Build MikroTik queries from perl structures

=head1 SYNOPSIS

  use MikroTik::Client::Query qw(build_query);

  # (a = 1 OR a = 2) AND (b = 3 OR c = 4 OR d = 5)
  my $query = {
      a => [1, 2],
      [
        b => 3,
        c => 4,
        d => 5
      ]
  };


  # Some bizarre nested expressions.
  # (a = 1 OR b = 2 OR (e = 5 AND f = 6 AND g = 7))
  #   OR
  # (c = 3 AND d = 4)
  #   OR
  # (h = 8 AND i = 9)
  $query = [
      -or  => {
          a => 1,
          b => 2,
          -and => {e => 5, f => 6, g => 7}
      },

      # OR
      -and => [
          c => 3,
          d => 4
      ],

      # OR
      {h => 8, i => 9}
  ];

=head1 DESCRIPTION

Simple and supposedly intuitive way to build MikroTik API queries. Following
ideas of L<SQL::Abstract>.

=head1 METHODS

=head2 build_query

  use MikroTik::Client::Query qw(build_query);

  # (type = 'ipip-tunnel' OR type = 'gre-tunnel') AND running = 'true'
  # $query
  #     = ['?type=ipip-tunnel', '?type=gre-tunnel', '?#|', '?running=true', '?#&'];
  my $query
      = build_query({type => ['ipip-tunnel', 'gre-tunnel'], running => 'true'});

Builds a query and returns an arrayref with API query words.

=head1 QUERY SYNTAX

Basic idea is that everything in arrayrefs are C<OR>'ed and everything in hashrefs
are C<AND>'ed unless specified otherwise. Another thing is, where a C<value> is
expected, you should be able to use a list to compare against a set of values.

=head2 Key-value pairs

  # type = 'gre-tunnel' AND running = 'true'
  my $query = {type => 'gre-tunnel', running => 'true'};

  # disabled = 'true' OR running = 'false'
  $query = [disabled => 'true', running => 'false'];

Simple attribute value comparison.

=head2 List of values

  # type = 'ether' OR type = 'wlan'
  my $query = {type => ['ether', 'wlan']};

You can use arrayrefs for a list of possible values for an attribute. By default,
it will be expanded into an C<OR> statement.

=head2 Comparison operators

  # comment isn't empty (more than empty string)
  my $query = {comment => {'>', ''}};

  # mtu > 1000 AND mtu < 1500
  $query = {mtu => {'<' => 1500, '>' => 1000}};

Hashrefs can be used for specifying operator for comparison. Well, any of three
of them. :) You can put multiple operator-value pairs in one hashref and they
will be expanded into an C<AND> statement.

  # mtu < 1000 OR mtu > 1500
  $query = {mtu => [{'<', 1000}, {'>', 1500}]};

  # Or like this
  # mtu < 1000 OR (mtu > 1400 AND mtu < 1500)
  $query = {mtu => [{'<', 1000}, {'>', 1400, '<', 1500}]};

Hashrefs can be also put in lists. If you want them combined into an C<OR>
statement, for example.

  # status = 'active' OR status = 'inactive'
  $query = {mtu => {'=', ['active', 'inactive']}};

Or you can use list as a value in a hashref pair. B<CAVEAT>: In this case, every
other pair in the hash will be ignored.

=head2 Negation

  # !(interface = 'ether5')
  my $query = {interface => {-not => 'ether5'}};

  # !(interface = 'ether5') AND !(interface = 'ether1')
  $query = {interface => {-not => [-and => 'ether5', 'ether1']}};

Since MikroTik API does not have 'not equal' operator, it ends up been 'opposite
of a equals b' expressions.

=head2 Checking for an attribute

  my $query = {-has => 'dafault-name'};

  $query = {-has_not => 'dafault-name'};

Checks if an element has an attribute with specific name.

=head2 Literal queries

  my $query = \['?type=ether', '?running=true', '?actual-mtu=1500', '?#&&'];

  $query = [
      type => 'ipip-tunnel',
      \['?type=ether', '?running=true', '?actual-mtu=1500', '?#&&']
  ];

Reference to an arrayref can be used to pass list of prepared words. Those will
be treated as blocks in nested expressions.

=head2 Logic and nesting

  # (mtu = 1460 AND actual-mtu = 1460)
  #   AND
  # (running = 'false' OR disabled = 'true')

  my $query = {
      {mtu     => 1460,    'actual-mtu' => 1460},
      [running => 'false', disabled     => 'true']
  };

Conditions can be grouped and nested if needed. It's like putting brackets around
them.

  # Same thing, but with prefixes
  my $query = {
      -and => [mtu     => 1460,    'actual-mtu' => 1460],
      -or  => {running => 'false', disabled     => 'true'}
  };

You can change logic applied to a block by using keywords. Those keywords
will go outside for blocks that affect multiple attributes, or ...

  # !(type = 'ether') AND !(type = 'wlan')

  # Will produce the same result
  my $query = {type => [-and => {-not => 'ether'}, {-not => 'wlan'}]};
  $query = {type => {-not => [-and => 'ether', 'wlan']}};

  # Wrong, second condition will replace first
  $query = {type => {-not => 'ether', -not => 'wlan'}};

... inside for a list of values of a single attribute.

  # This is wrong
  my $query = [
    -and =>
      {type => 'ether'},
      {running => 'true'}
  ];

  # It will actually results in
  # type = 'ether' OR running = 'true'

C<-and> will be treated as prefix for the first hashref and, since this hash has
only one element, won't affect anything at all.

=cut

