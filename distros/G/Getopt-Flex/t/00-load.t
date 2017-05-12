use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;

lives_ok { use Getopt::Flex } 'Getopt::Flex loaded ok';
lives_ok { require Getopt::Flex } 'Getopt::Flex required ok';
lives_ok { use Getopt::Flex::Config } 'Getopt::Flex::Config loaded ok';
lives_ok { require Getopt::Flex::Config } 'Getopt::Flex::Config required ok';
lives_ok { use Getopt::Flex::Spec } 'Getopt::Flex::Spec loaded ok';
lives_ok { require Getopt::Flex::Spec } 'Getopt::Flex::Spec required ok';
lives_ok { use Getopt::Flex::Spec::Argument } 'Getopt::Flex::Spec::Argument loaded ok';
lives_ok { require Getopt::Flex::Spec::Argument } 'Getopt::Flex::Spec::Argument required ok';
