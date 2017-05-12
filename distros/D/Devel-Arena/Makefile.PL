#!perl -w
use 5.005;
use ExtUtils::MakeMaker;
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use Config;
my $svh = "$Config{archlibexp}/CORE/sv.h";
my $sv_table_file = "sv-table.inc";
my $size_table_file = "sizes.inc";

{
    # Gah. MakeMaker in 5.6.2 (at least) is relying on $/;
    local $/;
    open FH, "<$svh" or die "Can't open $svh: $!";
    $_ = <FH>;
}

my ($enum) = /typedef\s+enum\s+{([^}]+)}\s+svtype;/s;
die "Can't parse $svh to find type enum ... svtype" unless defined $enum;

my @types;
my $count = 0;
while ($enum =~ m!SVt_(\w+),?\s+/\*\s+(\d+)\s+\*/!g) {
    die "enum parsing in $svh out of sync -- $count != $2" unless $count == $2;
    $types[$count] = $1;
    $count++;
}
die "Only found " . scalar (@types) . ", expected 16 or more" if @types < 16;

open FH, ">$sv_table_file" or die "Can't open $sv_table_file: $!";
print FH "const char *sv_names[] = {\n";
while (my $type = shift @types) {
    print FH qq{  "$type"};
    print FH "," if @types;
    print FH "\n";
}
print FH "};\n";
print FH "const size_t sv_names_len = sizeof(sv_names) / sizeof(char *);\n";
close FH or die "Can't close $sv_table_file: $!";

# Generate a table of names/sizes for things that we are interested in.
open FH, ">$size_table_file" or die "Can't open $size_table_file: $!";
foreach my $thing ('void *',
		   qw(HE HEK SV STRLEN size_t GP REGEXP PERL_CONTEXT BLOCK
		      MAGIC MGVTBL PerlInterpreter),
		   ($] >= 5.006 ? qw(PTR_TBL_ENT_t PTR_TBL_t) : ()),
		  (map {(uc ($_), "struct xpv$_")} qw(gv cv hv av io)),
		  (map {("struct xpv$_")} '', qw(iv uv nv mg lv bm fm)),
		  ) {
    print FH "  { \"$thing\", sizeof($thing) },\n";
}
foreach my $thing (qw(MEM_SIZE Size_t I32 U32 IV UV NV Off_t Fpos_t)) {
    print FH "#ifdef $thing\n  { \"$thing\", sizeof($thing) },\n#endif\n";
}
print FH "  { \"hek_key offset\", STRUCT_OFFSET(struct hek, hek_key) },\n";
# pre-5.6 doesn't define STRUCT_SV, and Devel::PPPort doesn't (yet)
if ($] >= 5.006) {
    print FH "  { \"struct sv\", sizeof(struct STRUCT_SV) },\n";
} else {
    print FH "  { \"struct sv\", sizeof(struct sv) },\n";
}
close FH or die "Can't close $size_table_file: $!";

WriteMakefile(
    NAME              => 'Devel::Arena',
    VERSION_FROM      => 'Arena.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Arena.pm', # retrieve abstract from module
       AUTHOR         => 'Nicholas Clark <nick@ccl4.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    realclean => {FILES=> $sv_table_file},
);
