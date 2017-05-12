package Handle;

sub TIEHANDLE {
  my $buf = "";
  bless \$buf
}

sub PRINT {
  my $buf = shift;
  $$buf .= join("", @_);
  1;
}

sub READLINE {
  my $buf = shift;
  return 0 unless length $$buf;
  $$buf =~ s/^(.*\n?)//;
  "$1";
}

sub READ {
  my $buf = shift;
  my $len = $_[1];
  $_[0] = substr($$buf, 0, $len, '');
  length $_[0];
}

1;
