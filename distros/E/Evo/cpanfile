requires 'perl',                 '5.22.0';
requires 'ExtUtils::MakeMaker',  '7.24';

on test => sub {
  requires 'Test::More', '0.88';
};

on 'develop' => sub {
  requires 'Pod::Coverage::TrustPod';
  requires 'Test::Perl::Critic', '1.02';
  requires 'Test::Pod', 0;
};
