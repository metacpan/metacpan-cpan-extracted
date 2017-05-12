use IO::Prompt;

my $answer = prompt 'Please select the most correct answer...', -1,
                    -menu => [
                        'Perl is an interpreted language',
                        'Perl is the Swiss Army Chainsaw',
                        'Perl rocks, dude!',
                        'All of the above',
                    ];

print "You chose: [$answer]\n\n";

   $answer = prompt 'Please select the most correct answer...', -1,
                    -menu => {
                        interpreted => 'Perl is an interpreted language',
                        Swiss       => 'Perl is the Swiss Army Chainsaw',
                        Rocks       => 'Perl rocks, dude!',
                        all         => 'All of the above',
                    };

print "You chose: [$answer]\n\n";
