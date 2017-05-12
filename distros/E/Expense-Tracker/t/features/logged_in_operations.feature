Feature: Operations as a logged in user
  As a user of the Expense Tracker application
  I want to be able to make CRUD operations on exposed resources
  In order to be sure that business logic of the application works as it should
  
  Background:
    Given a mojo test object for the "ExpenseTracker" application
      And the following users
      |username|password|email           |first_name|last_name |birth_date|
      |tudor   |123     |tudor@test.com  |tudor     |constantin|1982-26-08|
      |test1   |123     |test1@test.com  |tudor     |constantin|1982-26-08|
      |test2   |123     |test2@test.com  |tudor     |constantin|1982-26-08|
    When I create them through the REST API
     And I log in with username "tudor" and password "1234"
    Then I should see the "Username and password" text    
    When I log in with username "tudor" and password "123"
    Then I should see the "welcome tudor" text

  Scenario: Create currencies
    Given the following currencies
      |name|
      |EUR|
      |USD|
      |RON|
      |CAD|
    When I create them through the REST API
    Then I should be able to list their names
     And I should be able to get their ids
     And I should be able to delete them

