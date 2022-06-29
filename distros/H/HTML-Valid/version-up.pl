#!/home/ben/software/install/bin/perl
use Z;
use Trav::Dir;
use Deploy 'make_date';
do_system ("./build.pl -c");
my $td = Trav::Dir->new (
    only => qr!\.pm$!,
    no_trav => qr!\bblib\b!,
    rejfile => qr!HVB|Tagset!,
);
my $old = '0.08_02';
my $new = '0.09';
if ($old =~ /_/) {
    my $changes = "$Bin/Changes";
    my $date = make_date ('-');
    my $c = read_text ($changes);
    $c =~ s!\Q$old\E.*!$new $date!;
    write_text ($changes, $c);
}
my @files;
$td->find_files ($Bin, \@files);
for my $file (@files) {
    my $text = read_text ($file);
    if ($text !~ /\Q$old\E/) {
	warn "Version $old not in $file";
	next;
    }
    $text =~ s!\Q$old!$new!;
    write_text ($file, $text);
}
