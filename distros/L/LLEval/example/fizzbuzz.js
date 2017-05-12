#!lleval
for (var i = 0; i <= 30; i++){
    print (
        i % 15
            ? i % 5
                ? i % 3
                    ? i : 'Fizz'
                : 'Buzz'
            : 'FizzBuzz'
    );
}

