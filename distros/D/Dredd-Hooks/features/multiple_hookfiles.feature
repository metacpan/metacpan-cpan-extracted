Feature: Multiple hook files with a glob

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
    Given a file named "hookfile1.pl" with:
      """
      ## Implement before hook writing to standard output text: "It's me, File1"
      ##
      ## So, replace following pseudo code with yours:
    use strict;
    use warnings;

    use Dredd::Hooks::Methods;

    before(
        "/message > GET" => sub {
            my ($transaction) = @_;
            print "It's me, File1\n";
        }
    );
      """
    And a file named "hookfile2.pl" with:
      """
      ## Implement before hook writing to standard output text: "It's me, File2"
      ##
      ## So, replace following pseudo code with yours:
    use strict;
    use warnings;

    use Dredd::Hooks::Methods;

    before(
        "/message > GET" => sub {
            my ($transaction) = @_;
            print "It's me, File2\n";
        }
      )
      """
    And a file named "hookfile_to_be_globed.pl" with:
      """
      ## Implement before hook writing to standard output text: "It's me, File3"
      ##
      ## So, replace following pseudo code with yours:
    use strict;
    use warnings;

    use Dredd::Hooks::Methods;

    before(
        "/message > GET" => sub {
            my ($transaction) = @_;
            print "It's me, File3\n";
        }
    );
      """
    When I run `dredd ./apiary.apib http://localhost:4567 --server "ruby server.rb" --language dredd-hooks-perl --hookfiles ./hookfile1.pl --hookfiles ./hookfile2.pl --hookfiles ./hookfile_*.pl`
    Then the exit status should be 0
    And the output should contain:
      """
      It's me, File1
      """
    And the output should contain:
      """
      It's me, File2
      """
    And the output should contain:
      """
      It's me, File3
      """
