package Error::Pure::Output::JSON;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use JSON;
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err_json);

# Global variables.
our $PRETTY = 0;

# Version.
our $VERSION = 0.10;

# JSON print of backtrace.
sub err_json {
	my @errors = @_;
	my $ret_json;
	my $json = JSON->new;
	if ($PRETTY) {
		$ret_json = $json->pretty->encode(@errors);
	} else {
		$ret_json = $json->encode(@errors);
	}
	return $ret_json;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::Output::JSON - Output JSON subroutines for Error::Pure.

=head1 SYNOPSIS

 use Error::Pure::Output::JSON qw(err_json);
 print err_json(@errors);

=head1 SUBROUTINES

=over 8

=item C<err_json(@errors)>

 JSON print of backtrace.
 When is set global variable $PRETTY, print pretty output.
 Returns JSON serialization of backtrace.

=back

=head1 VARIABLES

=over 8

=item C<$PRETTY>

 JSON pretty output flag. Possible values are 0 or 1.
 Default value is 0.

=back

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::JSON qw(err_json);

 # Fictional error structure.
 my $err_hr = {
         'msg' => [
                 'FOO',
                 'KEY',
                 'VALUE',
         ],
         'stack' => [
                 {
                         'args' => '(2)',
                         'class' => 'main',
                         'line' => 1,
                         'prog' => 'script.pl',
                         'sub' => 'err',
                 }, {
                         'args' => '',
                         'class' => 'main',
                         'line' => 20,
                         'prog' => 'script.pl',
                         'sub' => 'eval {...}',
                 }
         ],
 };

 # Print out.
 print err_json($err_hr);

 # Output:
 # {"msg":["FOO","KEY","VALUE"],"stack":[{"sub":"err","prog":"script.pl","args":"(2)","class":"main","line":1},{"sub":"eval {...}","prog":"script.pl","args":"","class":"main","line":20}]}

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::JSON qw(err_json);

 # Set pretty output.
 $Error::Pure::Output::JSON::PRETTY = 1;

 # Fictional error structure.
 my $err_hr = {
         'msg' => [
                 'FOO',
                 'KEY',
                 'VALUE',
         ],
         'stack' => [
                 {
                         'args' => '(2)',
                         'class' => 'main',
                         'line' => 1,
                         'prog' => 'script.pl',
                         'sub' => 'err',
                 }, {
                         'args' => '',
                         'class' => 'main',
                         'line' => 20,
                         'prog' => 'script.pl',
                         'sub' => 'eval {...}',
                 }
         ],
 };

 # Print out.
 print err_json($err_hr);

 # Output:
 # {
 #    "msg" : [
 #       "FOO",
 #       "KEY",
 #       "VALUE"
 #    ],
 #    "stack" : [
 #       {
 #          "sub" : "err",
 #          "prog" : "script.pl",
 #          "args" : "(2)",
 #          "class" : "main",
 #          "line" : 1
 #       },
 #       {
 #          "sub" : "eval {...}",
 #          "prog" : "script.pl",
 #          "args" : "",
 #          "class" : "main",
 #          "line" : 20
 #       }
 #    ]
 # }

=head1 DEPENDENCIES

L<Exporter>,
L<JSON>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=item L<Error::Pure::Output::Text>

Output subroutines for Error::Pure.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Error-Pure-Output-JSON>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Špaček 2013-2015
 BSD 2-Clause License

=head1 VERSION

0.10

=cut
