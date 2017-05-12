use Test::More;

BEGIN {
    use_ok 'Glib::FindMinVersion';
}

local $/;
my $src = <DATA>;
is Glib::FindMinVersion::for_source($src), '2.6'; # for g_key_file_load_from_file

my %versions;

%versions = Glib::FindMinVersion::for_source($src);
is +keys(%versions), 3;
is +@{$versions{'2.0'}}, 3;

%versions = Glib::FindMinVersion::for_source($src, '2.0');
is +keys %versions, 2;

%versions = Glib::FindMinVersion::for_source($src, '2.26');
ok %versions == undef;

my ($max_in_list) = Glib::FindMinVersion::for_source($src, '2.0');
my $max_as_scalar = Glib::FindMinVersion::for_source($src, '2.0');

is $max_in_list, $max_as_scalar;

done_testing;

__DATA__
#include <glib.h>
static gboolean
epl_ishex(const char *num)
{
	if (g_str_has_prefix(num, "0x"))
		return TRUE;

	for (; g_ascii_isxdigit(*num); num++)
		;

	if (g_ascii_tolower(*num) == 'h')
		return TRUE;

	return FALSE;
}

#include <stdlib.h>

int main(void) {
	GKeyFile* gkf;
	if (!g_key_file_load_from_file(gkf, "rules.ini", G_KEY_FILE_NONE, NULL)){
		g_warning("Error: unable to parse file.");
	    return EXIT_FAILURE;
	}
    return EXIT_SUCCESS;
}


