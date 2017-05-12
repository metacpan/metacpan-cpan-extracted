#perl

package HTML::WebMake::PerlLib::CSVTableTag;

sub handle_csvtable_tag {
  my ($tagname, $attrs, $text, $self) = @_;
  local ($_);

  my $delim = $attrs->{delimiter};
  $delim ||= "\t";
  $delim = qr{\Q${delim}\E};
  delete $attrs->{delimiter};

  $_ = "<table ";
  my ($k, $v);
  while (($k, $v) = each %{$attrs}) { $_ .= "$k=\"$v\" "; }
  s/ $/>/g;
  my @out = ($_);

  my $csvfmt = undef;
  my @csvfmtkeys = ();

  foreach my $line (split (/\n/, $text)) {
    $line =~ s/^<!--.*?-->//;

    if ($line =~ s/^<csvfmt>\s*(.*?)\s*<\/csvfmt>//i) {
      $csvfmt = $1;
      @csvfmtkeys = ($csvfmt =~ m/\$(\d+)/g);
      my %uniq; map { $uniq{$_} = 1; } @csvfmtkeys;
      @csvfmtkeys = keys %uniq;
      next;
    }

    my @elems = split (/${delim}/, $line);
    next unless ($#elems >= 0);

    if (!defined $csvfmt) {
      # use the default format; just <tr>s and <td>s
      # this one can adapt to different numbers of cells per line
      $_ = '<tr><td>' . join ('</td><td>', @elems) . '</td></tr>';

    } else {
      # user-defined format
      $_ = $csvfmt;
      foreach my $i (@csvfmtkeys) {
	my $key = '$'.$i;
	my $val = $elems[$i-1]; if (!defined $val) { $val = ''; }
	s/\Q${key}\E/$val/g;
      }
    }

    push (@out, $_);
  }

  join ("\n", @out)."</table>";
}

1;
