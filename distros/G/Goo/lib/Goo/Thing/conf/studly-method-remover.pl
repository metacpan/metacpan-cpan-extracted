
use Goo::FileUtilities;

#my $filename = shift;

# all perl modules in the current dire 
foreach my $perl_file (glob("*.pm")) {

	my $output_file = "";

	foreach my $line (Goo::FileUtilities::get_file_as_lines($perl_file)) {

		# any method in a comment box
		if ($line =~ /^\#\s+(\S+)\s+\-/) {

				$line =~ s/([a-z])([A-Z])/\1\_\2/g;
                $line = lc($line);

		# any declared method
		} elsif ($line =~ /^sub\s+(\S+)\s+\{/) {
				
				$line =~ s/([a-z])([A-Z])/\1\_\2/g;
                $line = lc($line);

        # match $thing->callsStudlyMethod()
        } elsif ($line =~ m/\-\>([a-z]+[A-Z].*)\(/) {

                my $original_method_name = $1;
                my $method_name = $1;

				$method_name =~ s/([a-z])([A-Z])/\1\_\2/g;
                $method_name = lc($method_name);


                # studly caps!
                $line =~ s/\Q$original_method_name\E/$method_name/;

		
		# match Goo::Thing::pm::thing()
        } elsif ($line =~ m/\:\:([a-z]+[A-Z].*)\(/) {

                my $original_method_name = $1;
                my $method_name = $1;

				$method_name =~ s/([a-z])([A-Z])/\1\_\2/g;
                $method_name = lc($method_name);

                # studly caps!
                $line =~ s/\Q$original_method_name\E/$method_name/;

        } elsif ($line =~ m/\s([a-z]+[A-Z].*)\(/) {

                my $original_method_name = $1;
                my $method_name = $1;

				$method_name =~ s/([a-z])([A-Z])/\1\_\2/g;
                $method_name = lc($method_name);

                # studly caps!
                $line =~ s/\Q$original_method_name\E/$method_name/;

		}

        $output_file .= $line;

	}


	# print $output_file;
	Goo::FileUtilities::write_file($perl_file, $output_file);

}





__END__

=head1 NAME

 - 

=head1 SYNOPSIS

use ;

=head1 DESCRIPTION

=head1 METHODS


=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

