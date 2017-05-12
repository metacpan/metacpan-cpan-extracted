use MakeRegex 'make_regex';

open NICK, '<nicknames.txt' or die $!;
while(<NICK>)
{
  chomp;
  my($root,$nick,$akin)= split /\t/;
  @alt= split /\W+/, $nick;
  $match{$root}= [ map { push @{$root{$_}}, $root; $_ } @alt ];
  $akin{$root}= [ split /\W/, $akin ];
}
for(keys %root)
{
  if(@{$root{$_}} > 1)
  { $multi{$_}= delete $root{$_}; }
  else
  { $root{$_}= $root{$_}->[0]; }
}

print "%root=\n(\n";
for(sort keys %root)
{
  print "  $_ => '$root{$_}',\n";
}
print ");\n\n";

print "%multi=\n(\n";
for(sort keys %multi)
{
  print "  $_ => [qw<@{$multi{$_}}>],\n";
}
print ");\n\n";

print "%match=\n(\n";
for(sort keys %match)
{
  print "  $_ => qr/^(".make_regex(map {s/E$/\$E/;$_} ($_,@{$match{$_}})).")\$/, # @{$match{$_}}\n";
}
print ");\n\n";

print "%akin=\n(\n";
for(sort keys %akin)
{
  next unless @{$akin{$_}};
  print "  $_ => [qw<@{$akin{$_}}>],\n";
}
print ");\n\n";

