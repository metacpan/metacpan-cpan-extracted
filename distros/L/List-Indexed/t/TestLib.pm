
package TestLib;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	compare_structure
);


# Functionality: Compares two structures in order to decide
#           whether they are identical or not
# Parameters: The two structures (references)
# Returns: Whether the structures are identical (boolean)
#       True (1) - when they are identical, False (0) - otherwise

sub compare_structure
{
	my ($config1, $config2) = @_;

	if (ref($config1) eq 'ARRAY' &&
		ref($config2) eq 'ARRAY')
	{
		if (@{$config1} != @{$config2}) {
			return 0;
		}
		
		for (my $k=0; $k < @{$config1}; $k++)
		{
			my $val1 = $config1->[$k];
			my $val2 = $config2->[$k];

			if (! compare_structure($val1, $val2)) {
				return 0;
			}
		}
		return 1;
	}
	elsif (ref($config1) eq 'HASH' &&
		ref($config2) eq 'HASH')
	{
		if (scalar(keys %{$config1}) != scalar(keys %{$config2})) {
            return 0;
        }

		foreach $key (keys(%{$config1}))
		{
			$val1 = $config1->{$key};
			$val2 = $config2->{$key};

			if (! compare_structure($val1, $val2)) {
				return 0;
			}
		}
		return 1;
	}
	elsif (ref($config1) ne ref($config2)) {
		return 0;
	}	
	else {
		$val1 = "$config1";
		$val2 = "$config2";

		return ($val1 eq $val2);
	}
}


1;
