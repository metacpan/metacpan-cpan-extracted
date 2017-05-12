In this test dist, all authors are "John Doe", but the email addresses
differ in each file, allowing the tests to determine which file was
actually read. The Other.pod file is never used as a license source;
it simply exists to make sure that when "Other.pm" is explicitly set
as the license source, the module doesn't pick "Other.pod" instead,
even if it is available.
