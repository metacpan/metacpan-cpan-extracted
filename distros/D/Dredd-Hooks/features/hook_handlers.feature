Feature: Hook handlers

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
      ## Implement following in your language utilizing each hook declaring function
      ## from API in your language:
      ## - write to standard output name of hook + "hook handled" e.g: "after hook handled"
      ##
      ## So, replace following pseudo code with yours:
      #
    use strict;
    use warnings;

    use Dredd::Hooks::Methods;

    before(
        "/message > GET" => sub {
            my ($transaction) = @_;
            print "before hook handled\n";
        }
    );

    after(
        "/message > GET" => sub {
            my ($transaction) = @_;
            print "after hook handled\n";
        }
    );

    beforeValidation(
        "/message > GET" => sub {
            my ($transaction) = @_;
            print "before validation hook handled\n";
        }
    );

    beforeAll(
        sub {
            my ($transactions) = @_;
            print "before all hook handled\n";
        }
    );

    afterAll(
        sub {
            my ($transactions) = @_;
            print "after all hook handled\n";
        }
    );

    beforeEach(
        sub {
            my ($transaction) = @_;
            print "before each hook handled\n";
        }
    );

    beforeEachValidation(
        sub {
            my ($transaction) = @_;
            print "before each validation hook handled\n";
        }
    );

    afterEach(
        sub {
            my ($transaction) = @_;
            print "after each hook handled\n";
        }
    );
      """

    When I run `dredd ./apiary.apib http://localhost:4567 --server "ruby server.rb" --language dredd-hooks-perl --hookfiles ./hookfile.pl`
    Then the exit status should be 0
    Then the output should contain:
      """
      before hook handled
      """
    And the output should contain:
      """
      before validation hook handled
      """
    And the output should contain:
      """
      after hook handled
      """
    And the output should contain:
      """
      before each hook handled
      """
    And the output should contain:
      """
      before each validation hook handled
      """
    And the output should contain:
      """
      after each hook handled
      """
    And the output should contain:
      """
      before all hook handled
      """
    And the output should contain:
      """
      after all hook handled
      """
