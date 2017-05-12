{
    modules => ['Bcrypt'],
    modules_init => {
        Bcrypt => {
            salt => 'abracadabra12345',
            cost => 8
        }
    }
};
