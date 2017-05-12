package Devel::GDB::Reflect::DelegateProvider::Fallback;

use Devel::GDB::Reflect::MessageMethod qw( anon );

use warnings;
use strict;

sub new($)
{
	my $class = shift;

	return bless { };
}

sub get_delegates($$$$)
{
	my $self = shift;
	my ($initial_type, $initial_var, $reflector) = @_;

	my $is_class = $initial_type->{quotename} =~ /^(class|struct)/;

	return
	{
		print_open_brace  => $is_class ? "{" : "",
		print_close_brace => $is_class ? "}" : "",
		print_separator   => "",
		priority          => -1000,
		can_iterate       => 0,
		factory => sub
		{
			my ($var) = @_;

			return anon
			{
				print => sub
				{
					my ($callback, $fh) = @_;

					my $value = $reflector->eval($var);
					if(defined $value)
					{
						# Remove address part of strings
						$value =~ s/^0x[0-9a-f]+ (".*")$/$1/i;

						# If it's a class or struct, eliminate the braces and indentation
						if($is_class)
						{
							$value =~ s/^{//s;
							$value =~ s/}$//s;
							$value =~ s/^\n+//s;
							$value =~ s/\n+$//s;
							$value =~ s/^  //mg;
						}

						print $fh $value;
					}
					else
					{
						print $fh "(unknown)";
					}
				}
			}
		}
	};
}

1;
