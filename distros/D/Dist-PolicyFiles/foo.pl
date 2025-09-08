use strict;
use warnings;

use Data::Dumper;
# my @a = qw(dir
#                                         email
#                                         full_name
#                                         login
#                                         module
#                                         prefix
#                                         uncapitalize);
my $allowed = {map {$_ => "VAL: $_"} qw(dir
                                        email
                                        full_name
                                        login
                                        module
                                        prefix
                                        uncapitalize)};

print Dumper($allowed);

my $h = {x => 27};
@{$h}{qw(email full_name module)} = @{$allowed}{qw(email full_name module)};
print Dumper($h);

print Dumper($allowed);



