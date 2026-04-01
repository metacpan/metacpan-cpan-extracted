FOLLOW ALL THE RULES AND USE ELLEN.md AS GUIDE. NO QUESTION ASK. PLAN, DOCUMENT, ANALYSE, CODE, TEST, VERIFY, GIT COMMIT AND PUSH

1. All changes has to be tested and add unit tests to the t folder

2. All tests has to be passed and the test coverage has to be 100%

3. All changes has to be documentation in the doc folder

4. All bugs and issues will be added to FIXED_BUGS.md

5. All changes will need to be logged `Changes` file and versioned up and the version will need to link to the dist.ini for Dist::Zilla to build the cpan module

6. No emply commit and all commit has to have meaningful context of the changes with title.

7. All the MISTAKE.md ref will be use as git tag

8. Always proactively like ELLEN to check if there is any errors from the docker containers.

9. For Perl Modules

   - JSON use JSON::XS
   - HTTP / HTTPS use LWP::UserAgent
   - Capture::Tiny - capture command output

   Never Use:
   - LWP::Simple
   - HTTP::Tiny
   - JSON::PP

10. Always use Capture::Tiny like thi

use Capture::Tiny qw(capture);
my ($stdout, $stderr, $exit) = capture {
   system($command);
};

The exit code from capture() not a separate command.

11. do not use capture_merged, use capture instead

12. Also keep the POD updated in Developer/Dashboard.pm as well as README.md bot content identical bot POD is on to be display in different channel metacpan and README.md is for github. Both will need to have good coverage of the changes and will need to be updated to be in sync with the changes. That links to Rule #3

13. 100% of the codebase. The functions in the code will have a updated comment about it, what it is, input arguments and what output is to be expected. Since perl is a free type language. This will be nessary to have this notation.

14. 100% of the codebase, the scripts, test files and modeles also need to add and updted document about them in POD format under __END__ of the file.

15. Always do a security audit and fully 100% safe to use.

16. Ditch out all the code related to Companies House, ewf, xmlgw, chips, tuxedo, chs, grover, cidev, pbs and credential and sensitive data.

17. Do not delete OLD_CODE, do not change anything inside that folder. It is read only. Do not git commit or push anything inside of it.

18. If any changes related to frontend. Check on the browser to verify the changes are expected and usable.

19. If you found a problem, do not skip and do not stall and do not need to ask permission. FOLLOW ALL THE RULES AND USE ELLEN.md AS GUIDE. NO QUESTION ASK. PLAN, DOCUMENT, ANALYSE, CODE, TEST, VERIFY, GIT COMMIT AND PUSH

20. Make sure to run integation test and make sure the tar ball installed successful with cpanm `do not use --notest` so you can see if there is any error inside a blank environment docker container. doc/integration-test-plan.md

21. If there is a new version of tar ball from dzil, remove the old one and do not leave the old one at the working directory. Only keep the latest version.

22. For release to cpan PAUSE. You will need to do it locally, username is MICVU and password is in ~/.bashrc PAUSE_PASS and the passphrase for the ~/.ssh/mf is also at ~/.bashrc MF_PASS. Everytime. release to PAUSE tag PAUSE_RELEASED_HERE to git

23. Never surpress any errors. Expose them as much as possible. Then when an error show up. Fix it. Never hide them.

24. Make sure 100% fixed for any Kwalitee Issues.

25. Do not touch or inspect any unrelated Docker process from docker ps when working on integration test.
