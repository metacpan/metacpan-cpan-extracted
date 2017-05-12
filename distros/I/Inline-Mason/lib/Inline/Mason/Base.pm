package Inline::Mason::Base;

use strict;

our $VERSION = '0.01';

use Exporter;
our @EXPORT = qw(
		 $as_subs
		 $passive
		 $use_oo
		 $file_marker
		 $template
		 %taboo_word

		 err_taboo
		 );

our @ISA = qw(Exporter);


our $template;
our %taboo_word = map{$_=>1} qw(
				import
				load_mason
				load_file
				generate
				AUTOLOAD
				new
				err_taboo
				);

our $as_subs;
our $passive;
our $use_oo;
our $file_marker = qr/^__\w+__\n/o;
sub err_taboo {
    "This word '$_[0]' is reserved for internal use. Please rename it.";
}




1;
__END__
