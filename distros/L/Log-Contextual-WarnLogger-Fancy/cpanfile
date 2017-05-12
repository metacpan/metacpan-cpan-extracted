# vim: syntax=perl

# Note: Test requires have to propagate
#        to runtime requires when the module name matches
#        otherwise bad CPAN Clients merge the data wrong
#        and assume runtime requirement is the same
#        as the test one :/
requires 'Term::ANSIColor' => '2.01'; # colorstrip
requires perl => '5.006';
suggests 'Sub::Util';


on test => sub {
  requires 'Log::Contextual';
  requires 'Test::More'  => '0.89';
  requires 'Test::Needs' => '0.002000';
  requires 'Test::Differences';
  requires 'Term::ANSIColor' => '2.01'; # colorstrip
  recommends 'Sub::Util';
};
