# GenOOx-Data-File-SAMstar

## Summary
GenOO framework extension to read SAM files created by the STAR aligner.
Include it in your script and ask GenOO SAM parser to use it.

## Description
The GenOO framework SAM parser avoids code that is unique to specific programs and makes no assumptions for the optional fields in a SAM file. This module is a plugin for the GenOO framework and provides the functionality for reading SAM files generated from the STAR aligner. The module has been created on top of the generic GenOO SAM parser and to use it just include it in your scripts and ask GenOO SAM parser to use it.

## Example
```perl
# Create a parser
my $file_parser = GenOO::Data::File::SAM->new(
	file          => 'file.sam',
	records_class => 'GenOOx::Data::File::SAMstar::Record'
);

# Loop on the records of the file
while (my $record = $file_parser->next_record) {
	# $record is now an instance of GenOOx::Data::File::SAMstar::Record.
	print $record->cigar."\n"; # name
	print $record->flag."\n"; # flag
	print $record->number_of_mappings."\n"; # new stuff not present by default in GenOO
}
```

## Installation
* **Using CPAN** - Easier
  1. If you have cpanm installed. `cpanm GenOOx::Data::File::SAMstar`.
  2. If you do not have cpanm. See [here](http://www.cpan.org/modules/INSTALL.html).
* **Using Git** - Preferred so you may contribute
  1. Install git ([directions](http://git-scm.com/downloads)).
  2. Install dependencies (listed below) from CPAN. [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html).
  3. Clone the GenOO repository on your machine
     `git clone git@github.com:genoo/GenOOx-Sam-STAR.git`.
  4. To verify that everything works 
     `cd path/to/your/clone/; prove -l t/*.t;`.
  5. In the beginning of your perl script write the following
     `use lib 'path/to/your/clone/lib/'`.

## Dependencies (maybe not exhaustive)
* GenOO
* Modern::Perl
* Moose

## Copyright
Copyright (c) 2013 Emmanouil Maragkakis and Panagiotis Alexiou.

## License
This library is free software and may be distributed under the same terms as perl itself.

This library is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of merchantability or fitness for a particular purpose.
