package Finance::Tiller2QIF::Map;
# ABSTRACT: Apply mapping rules to categorize transactions
$Finance::Tiller2QIF::Map::VERSION = '1.08';
=head1 DESCRIPTION

Applies user-defined mapping rules to transactions in the SQLite database. Rules can filter by account, match transaction fields (category, payee, memo, date, amount), and set or suppress categories. Rules are evaluated in order; the first match wins.

=head1 FUNCTIONS

=head2 Map

  Finance::Tiller2QIF::Map::Map( $db_path, $mapfile );

Apply mapping rules from C<$mapfile> to transactions in the database. C<$mapfile> is optional; if omitted, transactions pass through unchanged. Rules are evaluated in order; the first matching rule sets the transaction's C<mapped_category> and/or C<skipped> flag.

=head2 Rule ordering

Rules are first-match-wins, so order matters. If a rule is not firing as expected, the most common cause is that an earlier rule is capturing the transaction first.

Place specific overrides I<before> broad rules. For example, a C<payee | Wawa | blank> rule must appear before any C<category | Groceries | Expenses:Groceries> rule, or the category rule will match Wawa transactions first and the payee rule will never be evaluated.

A good convention is to put specific payee and memo overrides near the top, and broad category-renaming rules (which map source categories to chart-of-accounts names) near the bottom. Category renaming is the least specific operation and should generally be last.

=head1 AUTHOR

John Karr E<lt>brainbuz@cpan.orgE<gt>

=head1 LICENSE

GPL version 3 or later.

=cut

use v5.34;

use Mojo::SQLite;
use Path::Tiny;
use utf8;
use warnings FATAL => 'utf8';
use feature qw/signatures postderef/;
use open ':std', ':encoding(UTF-8)';

no warnings 'experimental::try';
use feature 'try';

my %VALID_FIELDS = map { $_ => 1 } qw(category payee memo account date amount);

sub _resolve_dest ($dest) {
  return undef if $dest eq 'source';
  return ''    if $dest eq 'blank';
  return $dest;
}

sub _parse_line ($line) {
  # Slash-delimited pattern: field | /regex/ | dest
  if ( $line =~ /^([^|]+?)\s*\|\s*\/((?:[^\/]|\\.)*?)\/\s*\|\s*(.+?)$/ ) {
    return (
      scalar( $1 =~ s/^\s+|\s+$//gr ),
      $2,
      scalar( $3 =~ s/^\s+|\s+$//gr ),
    );
  }
  # Simple three-field split: no | allowed in pattern except \| for literal pipe
  my @parts = split /(?<!\\)\|/, $line;
  die "Bare alternation without slash-quoting\n"
    if @parts > 3;

  @parts = map { s/^\s+|\s+$//gr } @parts;
  my $field   = shift @parts;
  my $dest    = pop @parts;
  my $pattern = $parts[0] // '';
  return ( $field, $pattern, $dest );
}

sub _parse_mapping_file ($file) {
  my @rules;
  my $default      = undef;  # parse-time constant: undef means use source category
  my $default_skip = 0;      # parse-time constant: reset into $skip at the top of each tx loop
                             # defined from default rule $dest.

  my $lineno = 0;
  for my $line ( path($file)->lines_utf8({ chomp => 1 }) ) {
    $lineno++;
    next if $line =~ /^\s*(?:#|$)/;

    # Optional account filter: [AccountPattern] at start of line.
    # Pattern follows the same alternation rules as field patterns.
    my $acct_re = undef;
    if ( $line =~ s/^\s*\[([^\]]+)\]\s*// ) {
      my $acct_pat = $1;
      $acct_re = eval { qr/$acct_pat/i }
        or die "Invalid account filter '[$acct_pat]' at line $lineno: $@\n";
    }

    my ($field, $pattern, $dest) = _parse_line($line);
    $field = lc $field;
    $dest =~ s/\\\|/|/g if defined $dest;

    if ( $field eq 'default' ) {
      die "Account filter not valid on default line at line $lineno\n"
        if defined $acct_re;
      die "Default line missing destination at line $lineno\n"
        unless defined $dest && length $dest;
      $default_skip = ( $dest eq 'skip' ? 1 : 0 );
      $default      = ( $dest eq 'skip' ? undef : _resolve_dest($dest) );
      next;
    }

    die "Unknown field '$field' at line $lineno. Valid fields: "
      . join( ', ', sort keys %VALID_FIELDS ) . "\n"
      unless $VALID_FIELDS{$field};

    die "Missing pattern at line $lineno\n"
      unless length $pattern;

    die "Missing destination at line $lineno (use 'blank' for empty category)\n"
      unless defined $dest && length $dest;

    my $re_src = ( $pattern eq '*' ) ? '.*' : $pattern;
    my $re = eval { qr/$re_src/i }
      or die "Invalid regex '$pattern' at line $lineno: $@\n";

    my $is_skip = ( $dest eq 'skip' ? 1 : 0 );
    push @rules, {
      field          => $field,
      pattern        => $re,
      pattern_str    => $pattern,
      destination    => ( $is_skip ? undef : _resolve_dest($dest) ),
      skip           => $is_skip,
      account_filter => $acct_re,
    };
  }

  return ( \@rules, $default, $default_skip );
}

sub _run_sql_file ( $dbmojo, $file, $verbose ) {
  my $sql = path($file)->slurp_utf8;
  my @statements;
  my $current = '';
  for my $line ( split /\n/, $sql ) {
    $current .= $line . "\n";
    if ( $line =~ /;\s*$/ ) {
      push @statements, $current;
      $current = '';
    }
  }
  push @statements, $current if $current =~ /\S/;
  for my $stmt (@statements) {
    my $rows = $dbmojo->dbh->do($stmt);
    if ( $verbose ) {
      ( my $summary = $stmt ) =~ s/\s+/ /g;
      $summary =~ s/^\s+|\s+$//g;
      # dbi returns 0E0 meaning 0 but true
      say "  " . int($rows) . " row(s) affected: $summary";
    }
  }
}

sub Map ( $options ) {

  return unless defined $options->{mapfile};
  my $mapfile   = $options->{mapfile};
  my $db_path   = $options->{db_path};
  my $verbose   = $options->{verbose}   || 0;
  my $beforemap = $options->{beforemap} // undef;
  my $aftermap  = $options->{aftermap}  // undef;
  my ( $rules, $default, $default_skip ) = _parse_mapping_file($mapfile);

  my $dbmojo = Mojo::SQLite->new($db_path)->options({ sqlite_unicode => 1 })->db;

  if ( defined $beforemap ) {
    say "Running beforemap: $beforemap" if $verbose;
    try {
      _run_sql_file( $dbmojo, $beforemap, $verbose );
      say "beforemap completed successfully" if $verbose;
    }
    catch ($e) { warn "beforemap error: $e" }
  }

  my @transactions = $dbmojo->select( 'transactions', '*', { exported => 0 } )->hashes->@*;

  for my $tx (@transactions) {
    my $mc   = $default;       # reset each tx; overwritten if a rule matches
    my $skip = $default_skip;  # reset each tx; overwritten if a rule matches
    my $matched_rule;

    MAPRULE: for my $rule (@$rules) {
      if ( defined $rule->{account_filter} ) {
        next MAPRULE unless $tx->{account} =~ $rule->{account_filter};
      }
      my $val = $tx->{ $rule->{field} };
      next MAPRULE unless defined $val;
      if ( $val =~ $rule->{pattern} ) {
        $mc   = $rule->{destination};
        $skip = $rule->{skip};
        $matched_rule = "$rule->{field} ~ /$rule->{pattern_str}/ => " . ($rule->{skip} ? 'skip' : ($mc // 'source'));
        last MAPRULE;
      }
    }

    if ($verbose) {
      my $result = $matched_rule // 'default';
      say "TX $tx->{id} ($tx->{payee}): $result";
    }

    $dbmojo->update( 'transactions',
      { mapped_category => $mc, skipped => $skip, exported => $skip },
      { id => $tx->{id} } );
  }

  if ( defined $aftermap ) {
    say "Running aftermap: $aftermap" if $verbose;
    try {
      _run_sql_file( $dbmojo, $aftermap, $verbose );
      say "aftermap completed successfully" if $verbose;
    }
    catch ($e) { warn "aftermap error: $e" }
  }

  $dbmojo->disconnect;
}

1;
