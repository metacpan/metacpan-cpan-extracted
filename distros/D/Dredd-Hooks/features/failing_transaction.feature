Feature: Failing a transaction

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

  @debug
  Scenario:
    Given a file named "hookfile.pl" with:
      """
    use strict;
    use warnings;

    use Dredd::Hooks::Methods;

    before(
        "/message > GET" => sub {
            my ($transaction) = @_;
            $transaction->{fail} = 'Yay! Failed!';
        }
    );
      """
    When I run `dredd ./apiary.apib http://localhost:4567 --server "ruby server.rb" --language "dredd-hooks-perl" --hookfiles ./hookfile.pl`
    Then the exit status should be 1
    And the output should contain:
      """
      Yay! Failed!
      """
