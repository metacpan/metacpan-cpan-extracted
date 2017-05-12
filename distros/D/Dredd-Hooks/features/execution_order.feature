Feature: Execution order

  Background:
    Given I have "dredd-hooks-perl" command installed
    And I have "dredd" command installed
    And a file named "server.rb" with:
      """
      require 'sinatra'
      get '/message' do
        "Hello World!\n\n"
      end
      """

    And a file named "apiary.apib" with:
      """
      # My Api
      ## GET /message
      + Response 200 (text/html;charset=utf-8)
          Hello World!
      """

  @announce
  Scenario:
    Given a file named "hookfile.pl" with:
      """
use strict;
use warnings;

use Dredd::Hooks::Methods;

my $key = 'hooks_modifications';
before(
    "/message > GET" => sub {
        my ($transaction) = @_;
        $transaction->{$key} = [] unless $transaction->{$key};
        push @{ $transaction->{$key} }, "before modification";
    }
);

after(
    "/message > GET" => sub {
        my ($transaction) = @_;
        $transaction->{$key} = [] unless $transaction->{$key};
        push @{ $transaction->{$key} }, "after modification";
    }
);

beforeValidation(
    "/message > GET" => sub {
        my ($transaction) = @_;
        $transaction->{$key} = [] unless $transaction->{$key};
        push @{ $transaction->{$key} }, "before validation modification";
    }
);

beforeAll(
    sub {
        my ($transactions) = @_;
        $transactions->[0]{$key} = [] unless $transactions->[0]{$key};
        push @{ $transactions->[0]{$key} }, "before all modification";
    }
);

afterAll(
    sub {
        my ($transaction) = @_;
        $transaction->[0]{$key} = [] unless $transaction->[0]{$key};
        push @{ $transaction->[0]{$key} }, "after all modification";
    }
);

beforeEach(
    sub {
        my ($transaction) = @_;
        $transaction->{$key} = [] unless $transaction->{$key};
        push @{ $transaction->{$key} }, "before each modification";
    }
);

beforeEachValidation(
    sub {
        my ($transaction) = @_;
        $transaction->{$key} = [] unless $transaction->{$key};
        push @{ $transaction->{$key} }, "before each validation modification";
    }
);

afterEach(
    sub {
        my ($transaction) = @_;
        $transaction->{$key} = [] unless $transaction->{$key};
        push @{ $transaction->{$key} }, "after each modification";
    }
);
      """
    Given I set the environment variables to:
      | variable                       | value      |
      | TEST_DREDD_HOOKS_HANDLER_ORDER | true       |

    When I run `dredd ./apiary.apib http://localhost:4567 --server "ruby server.rb" --language dredd-hooks-perl --hookfiles ./hookfile.pl`
    Then the exit status should be 0
    Then the output should contain:
      """
      0 before all modification
      1 before each modification
      2 before modification
      3 before each validation modification
      4 before validation modification
      5 after modification
      6 after each modification
      7 after all modification
      """
