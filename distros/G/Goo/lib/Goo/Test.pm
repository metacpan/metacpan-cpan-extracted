package Goo::Test;


my $option = "Goo::Thing::pm::PackageProfileOption";

eval "use $option;";

my $gtpm = $option->new();




1;



__END__

=head1 NAME

Goo::Test - 

=head1 SYNOPSIS

use Goo::Test;

=head1 DESCRIPTION



=head1 METHODS

=over


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

