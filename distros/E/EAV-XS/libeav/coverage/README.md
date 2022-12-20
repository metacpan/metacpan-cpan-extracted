This directory used to keep coverage files.

The information below describes the usage of [gcovr](https://github.com/gcovr/gcovr)
for this repository.

For instance:

```
# create coverage-specific build
% make coverage MY_FLAG=ON

# generate report
% gcovr --exclude-directories tests -o ./coverage/report.txt

# or better
% gcovr --exclude-directories tests --html ./coverage/report.html

# or much better (lot's of details)
% gcovr --exclude-directories tests --html-details ./coverage/report.html

# don't forget to cleanup using the same build options
% make clean MY_FLAG=ON

# (optionally) clean all coverage reports inside ./coverage dir
% make clean-coverage
```

### See also

* [coverage.sh](/misc/coverage.sh) script file
* the target `gcovr` inside of [Makefile](/Makefile)
